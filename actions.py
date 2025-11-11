import os, json, time, requests, psycopg2, logging
from typing import Dict, Text, Any, List, Optional
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet

# Configuración de conexiones - soporta Docker y local
# En Docker: usa nombres de servicios (postgres, qdrant)
# Local: usa localhost
IS_DOCKER = os.getenv("DOCKER_ENV", "false").lower() == "true"
HOST_POSTGRES = "postgres" if IS_DOCKER else "localhost"
HOST_QDRANT = "qdrant" if IS_DOCKER else "localhost"

PG_DSN = os.getenv("PG_DSN", f"dbname=atcdb user=atc password=atc_pass host={HOST_POSTGRES}")

class ActionRegisterQuote(Action):
    def name(self):
        return "action_register_quote"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain):
        producto = tracker.get_slot("producto")
        sku = tracker.get_slot("sku")
        cantidad = tracker.get_slot("cantidad")
        sender = tracker.sender_id
        ts = int(time.time())

        conn = psycopg2.connect(PG_DSN); conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(
              "INSERT INTO interactions(conversation_id,resumen,productos,created_at) VALUES(%s,%s,%s,now())",
              (sender, f"Cotización {producto} x {cantidad}", json.dumps([{{"producto":producto,"sku":sku,"cantidad":cantidad}}]))
            )
        conn.close()

        if os.getenv("GOOGLE_SHEET_ID") and os.getenv("GOOGLE_API_KEY"):
            payload = {{"values": [[ts, sender, producto, sku, cantidad]]}}
            rng = "Cotizaciones!A1"
            url = f"https://sheets.googleapis.com/v4/spreadsheets/{{os.getenv('GOOGLE_SHEET_ID')}}/values/{{rng}}:append?valueInputOption=USER_ENTERED&key={{os.getenv('GOOGLE_API_KEY')}}"
            try:
                requests.post(url, json=payload, timeout=8)
            except Exception:
                pass

        dispatcher.utter_message("¡Listo! Registré tu solicitud de cotización.")
        return []

# ==========================================
# SISTEMA DE CORRECCIÓN Y BASE DE CONOCIMIENTO
# ==========================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

QDRANT_URL = os.getenv("QDRANT_URL", f"http://{HOST_QDRANT}:6333")
KB_COLLECTION = os.getenv("KB_COLLECTION", "knowledge_base")

# Intentar importar Qdrant, si no está disponible usaremos PostgreSQL
try:
    from qdrant_client import QdrantClient
    from qdrant_client.models import Distance, VectorParams, PointStruct
    QDRANT_AVAILABLE = True
except ImportError:
    QDRANT_AVAILABLE = False
    logger.warning("Qdrant no está disponible. Usando PostgreSQL para base de conocimiento.")

class KnowledgeBaseManager:
    """Gestor de base de conocimiento con soporte para Qdrant y PostgreSQL"""
    
    def __init__(self):
        self.qdrant_client = None
        if QDRANT_AVAILABLE:
            try:
                self.qdrant_client = QdrantClient(url=QDRANT_URL)
                self._ensure_collection()
                logger.info("✅ Conectado a Qdrant")
            except Exception as e:
                logger.warning(f"⚠️ No se pudo conectar a Qdrant: {e}. Usando PostgreSQL.")
                self.qdrant_client = None
    
    def _ensure_collection(self):
        """Asegura que la colección existe en Qdrant"""
        if not self.qdrant_client:
            return
        try:
            self.qdrant_client.get_collection(KB_COLLECTION)
        except Exception:
            # Crear colección si no existe (384 es el tamaño común para sentence-transformers)
            self.qdrant_client.create_collection(
                collection_name=KB_COLLECTION,
                vectors_config=VectorParams(size=384, distance=Distance.COSINE)
            )
            logger.info(f"✅ Colección '{KB_COLLECTION}' creada en Qdrant")
    
    def save_correction(self, topic: str, correction: str, context: Dict[str, Any] = None):
        """Guarda una corrección en la base de conocimiento"""
        timestamp = int(time.time())
        data = {
            "topic": topic,
            "correction": correction,
            "context": context or {},
            "timestamp": timestamp,
            "type": "correction"
        }
        
        # Intentar guardar en Qdrant
        if self.qdrant_client:
            try:
                # Para simplificar, usamos un vector dummy (en producción usarías embeddings reales)
                point = PointStruct(
                    id=timestamp,
                    vector=[0.0] * 384,  # Vector dummy - en producción generar embedding real
                    payload=data
                )
                self.qdrant_client.upsert(
                    collection_name=KB_COLLECTION,
                    points=[point]
                )
                logger.info(f"✅ Corrección guardada en Qdrant: {topic}")
                return True
            except Exception as e:
                logger.error(f"Error guardando en Qdrant: {e}")
        
        # Fallback a PostgreSQL
        try:
            conn = psycopg2.connect(PG_DSN)
            conn.autocommit = True
            with conn.cursor() as cur:
                # Crear tabla si no existe
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS knowledge_base (
                        id SERIAL PRIMARY KEY,
                        topic TEXT,
                        correction TEXT,
                        context JSONB,
                        timestamp BIGINT,
                        type TEXT,
                        created_at TIMESTAMP DEFAULT NOW()
                    )
                """)
                cur.execute("""
                    INSERT INTO knowledge_base (topic, correction, context, timestamp, type)
                    VALUES (%s, %s, %s, %s, %s)
                """, (topic, correction, json.dumps(context or {}), timestamp, "correction"))
            conn.close()
            logger.info(f"✅ Corrección guardada en PostgreSQL: {topic}")
            return True
        except Exception as e:
            logger.error(f"Error guardando en PostgreSQL: {e}")
            return False
    
    def search_knowledge(self, query: str, limit: int = 5) -> List[Dict]:
        """Busca en la base de conocimiento"""
        results = []
        
        # Buscar en PostgreSQL (más simple para búsqueda de texto)
        try:
            conn = psycopg2.connect(PG_DSN)
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT topic, correction, context, timestamp
                    FROM knowledge_base
                    WHERE topic ILIKE %s OR correction ILIKE %s
                    ORDER BY timestamp DESC
                    LIMIT %s
                """, (f"%{query}%", f"%{query}%", limit))
                for row in cur.fetchall():
                    results.append({
                        "topic": row[0],
                        "correction": row[1],
                        "context": row[2] if isinstance(row[2], dict) else json.loads(row[2]) if row[2] else {},
                        "timestamp": row[3]
                    })
            conn.close()
        except Exception as e:
            logger.error(f"Error buscando en PostgreSQL: {e}")
        
        return results

# Instancia global del gestor de conocimiento
kb_manager = KnowledgeBaseManager()

class ActionHandleCorrection(Action):
    """Maneja correcciones del usuario y actualiza la base de conocimiento"""
    
    def name(self) -> Text:
        return "action_handle_correction"
    
    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict]:
        # Obtener el mensaje del usuario
        user_message = tracker.latest_message.get("text", "")
        
        # Obtener el último mensaje del bot para contexto
        bot_messages = [event for event in tracker.events if event.get("event") == "bot"]
        last_bot_message = bot_messages[-1].get("text", "") if bot_messages else ""
        
        # Extraer información de la corrección
        correction_data = self._extract_correction(user_message, last_bot_message)
        
        if correction_data:
            topic = correction_data.get("topic", "general")
            correction = correction_data.get("correction", user_message)
            
            # Guardar en base de conocimiento
            context = {
                "user_message": user_message,
                "bot_message": last_bot_message,
                "conversation_id": tracker.sender_id,
                "slots": {slot: tracker.get_slot(slot) for slot in tracker.slots.keys()}
            }
            
            success = kb_manager.save_correction(topic, correction, context)
            
            if success:
                dispatcher.utter_message(
                    f"✅ Gracias por la corrección. He actualizado la base de conocimiento sobre '{topic}'. "
                    f"La próxima vez recordaré: {correction}"
                )
            else:
                dispatcher.utter_message(
                    "⚠️ Entendí tu corrección, pero hubo un problema al guardarla. "
                    "La tendré en cuenta para esta conversación."
                )
        else:
            dispatcher.utter_message(
                "Entiendo que algo está mal. ¿Podrías ser más específico? "
                "Por ejemplo: 'El precio está mal, debería ser $100' o 'El producto se llama diferente'"
            )
        
        return []
    
    def _extract_correction(self, user_message: str, bot_message: str) -> Optional[Dict[str, str]]:
        """Extrae información de la corrección del mensaje del usuario"""
        user_lower = user_message.lower()
        
        # Patrones comunes de corrección
        patterns = {
            "precio": ["precio", "cuesta", "vale", "costo", "$"],
            "producto": ["producto", "artículo", "item", "se llama"],
            "cantidad": ["cantidad", "unidades", "piezas"],
            "información": ["información", "datos", "detalles", "info"]
        }
        
        # Identificar el tema
        topic = "general"
        for key, keywords in patterns.items():
            if any(keyword in user_lower for keyword in keywords):
                topic = key
                break
        
        # Intentar extraer la corrección específica
        correction = user_message
        
        # Buscar frases como "debería ser", "es", "correcto es"
        correction_phrases = ["debería ser", "es", "correcto es", "en realidad es", "mejor dicho"]
        for phrase in correction_phrases:
            if phrase in user_lower:
                parts = user_message.split(phrase, 1)
                if len(parts) > 1:
                    correction = parts[1].strip()
                    break
        
        return {
            "topic": topic,
            "correction": correction
        }

class ActionSearchKnowledge(Action):
    """Busca en la base de conocimiento"""
    
    def name(self) -> Text:
        return "action_search_knowledge"
    
    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict]:
        query = tracker.latest_message.get("text", "")
        
        if not query:
            dispatcher.utter_message("¿Sobre qué tema querés buscar información?")
            return []
        
        results = kb_manager.search_knowledge(query, limit=3)
        
        if results:
            response = "Encontré esta información:\n\n"
            for i, result in enumerate(results, 1):
                response += f"{i}. **{result['topic']}**: {result['correction']}\n"
            dispatcher.utter_message(response)
        else:
            dispatcher.utter_message(f"No encontré información sobre '{query}' en la base de conocimiento.")
        
        return []

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: rasa-actions-v3
# version: 3.0.0
# file: rasa/actions.py
# lang: py
# created_at: 2025-10-31T00:10:55Z
# author: GPT-5 Thinking
# origin: rasa-impl
# body_sha256: 042a5186e559e23d70fa46dd6220c5a9caf6f55e65d34ebc829d9783d7ed1232
