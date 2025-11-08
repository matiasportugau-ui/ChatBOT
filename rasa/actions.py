# AUTO-ATC Playbook v3 - Rasa Actions
# Acciones customizadas para chatbot con integración Qdrant, PostgreSQL y validación de seguridad

import os
import json
import time
import re
import logging
import requests
from typing import Dict, Text, Any, List
from datetime import datetime, timedelta

import psycopg2
import psycopg2.extras
from qdrant_client import QdrantClient
from qdrant_client.http import models
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet, FollowupAction, UserUtteranceReverted
from rasa_sdk.forms import FormAction

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuración de conexiones
class DatabaseManager:
    def __init__(self):
        self.dsn = os.getenv("DATABASE_URL", "postgresql://atc_user:atc_pass@postgres:5432/atc_db")
        self.qdrant_url = os.getenv("QDRANT_URL", "http://qdrant:6333")
        self.qdrant_client = QdrantClient(url=self.qdrant_url)

    def get_connection(self):
        return psycopg2.connect(self.dsn)

    def validate_input(self, input_text: str, input_type: str = "text") -> bool:
        """Valida inputs del usuario para prevenir inyección y contenido malicioso"""
        if not input_text or len(input_text.strip()) == 0:
            return False

        # Sanitización básica
        input_text = input_text.strip()

        # Validaciones por tipo
        if input_type == "email":
            email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
            return bool(re.match(email_pattern, input_text))
        elif input_type == "phone":
            # Solo números, espacios, guiones, paréntesis, y signos +
            phone_pattern = r'^[\+]?[0-9\s\-\(\)]{8,20}$'
            return bool(re.match(phone_pattern, input_text))
        elif input_type == "quantity":
            try:
                qty = int(input_text)
                return 1 <= qty <= 1000  # Límite razonable
            except ValueError:
                return False
        else:
            # Texto general: longitud máxima y caracteres permitidos
            return len(input_text) <= 500 and not re.search(r'[<>]', input_text)

    def search_knowledge_base(self, query: str, limit: int = 3) -> List[Dict]:
        """Busca en la knowledge base usando Qdrant"""
        try:
            # Para desarrollo, devolver datos mock si no hay embeddings
            if not self.qdrant_client.collection_exists("products"):
                return self._get_mock_kb_results(query, limit)

            # En producción: búsqueda por similitud vectorial
            # Aquí iría el código para generar embedding y buscar
            return self._get_mock_kb_results(query, limit)

        except Exception as e:
            logger.error(f"Error searching knowledge base: {e}")
            return []

    def _get_mock_kb_results(self, query: str, limit: int) -> List[Dict]:
        """Resultados mock para desarrollo"""
        mock_products = [
            {
                "title": "Laptop Dell XPS 13",
                "content": "Laptop premium Dell XPS 13, procesador Intel i7, 16GB RAM, 512GB SSD. Precio: $1,299",
                "category": "computadoras",
                "price": 1299.00
            },
            {
                "title": "iPhone 15 Pro",
                "content": "Smartphone Apple iPhone 15 Pro 128GB, cámara avanzada, procesador A17. Precio: $999",
                "category": "celulares",
                "price": 999.00
            },
            {
                "title": "Auriculares Sony WH-1000XM5",
                "content": "Auriculares inalámbricos Sony con cancelación de ruido premium. Precio: $349",
                "category": "audio",
                "price": 349.00
            }
        ]

        # Filtrar por query básica
        results = [p for p in mock_products if query.lower() in p["title"].lower() or query.lower() in p["category"]]
        return results[:limit]

    def save_quote(self, conversation_id: str, product_data: Dict) -> bool:
        """Guarda cotización en base de datos"""
        try:
            with self.get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO quotes (conversation_id, status, products, total_amount, currency, valid_until, created_at)
                        VALUES (%s, 'draft', %s, %s, 'USD', %s, now())
                    """, (
                        conversation_id,
                        json.dumps([product_data]),
                        product_data.get('price', 0) * product_data.get('quantity', 1),
                        datetime.now() + timedelta(days=7)  # Válida por 7 días
                    ))
                conn.commit()
            return True
        except Exception as e:
            logger.error(f"Error saving quote: {e}")
            return False

# Instancia global del manager de BD
db_manager = DatabaseManager()

# ==========================================
# ACCIONES CUSTOMIZADAS
# ==========================================

class ActionSearchProduct(Action):
    """Busca productos en la knowledge base"""

    def name(self) -> Text:
        return "action_search_product"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        user_query = tracker.latest_message.get('text', '')

        if not db_manager.validate_input(user_query):
            dispatcher.utter_message(text="Lo siento, no pude entender tu búsqueda. ¿Puedes ser más específico?")
            return []

        results = db_manager.search_knowledge_base(user_query)

        if not results:
            dispatcher.utter_message(text="No encontré productos que coincidan con tu búsqueda. ¿Puedes darme más detalles?")
            return []

        # Mostrar resultados encontrados
        response = "Encontré los siguientes productos:\n\n"
        for i, product in enumerate(results, 1):
            response += f"{i}. {product['title']}\n"
            response += f"   {product['content']}\n\n"

        dispatcher.utter_message(text=response)
        return [SlotSet("search_results", results)]

class ActionRegisterQuote(Action):
    """Registra una cotización completa"""

    def name(self) -> Text:
        return "action_register_quote"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        # Obtener slots
        producto = tracker.get_slot("producto")
        sku = tracker.get_slot("sku")
        cantidad = tracker.get_slot("cantidad")
        email = tracker.get_slot("email")
        telefono = tracker.get_slot("telefono")

        # Validaciones
        if not producto or not db_manager.validate_input(producto):
            dispatcher.utter_message(text="Por favor especifica un producto válido.")
            return [FollowupAction("utter_ask_producto")]

        if cantidad and not db_manager.validate_input(str(cantidad), "quantity"):
            dispatcher.utter_message(text="Por favor indica una cantidad válida (1-1000).")
            return [FollowupAction("utter_ask_cantidad")]

        if email and not db_manager.validate_input(email, "email"):
            dispatcher.utter_message(text="Por favor proporciona un email válido.")
            return [SlotSet("email", None), FollowupAction("utter_ask_email")]

        if telefono and not db_manager.validate_input(telefono, "phone"):
            dispatcher.utter_message(text="Por favor proporciona un teléfono válido.")
            return [SlotSet("telefono", None), FollowupAction("utter_ask_telefono")]

        # Preparar datos de cotización
        quote_data = {
            "producto": producto,
            "sku": sku or "N/A",
            "cantidad": int(cantidad) if cantidad else 1,
            "email": email,
            "telefono": telefono,
            "timestamp": int(time.time())
        }

        # Buscar precio en KB
        kb_results = db_manager.search_knowledge_base(producto, limit=1)
        if kb_results:
            quote_data["price"] = kb_results[0].get("price", 0)
            quote_data["product_info"] = kb_results[0]

        # Guardar en base de datos
        conversation_id = tracker.sender_id
        if db_manager.save_quote(conversation_id, quote_data):
            # Integración con Google Sheets (opcional)
            self._save_to_google_sheets(quote_data)

            response = f"¡Perfecto! Registré tu cotización para {producto}"
            if cantidad:
                response += f" x {cantidad}"
            if email:
                response += f". Te contactaremos al email {email}"
            response += "."

            dispatcher.utter_message(text=response)

            # Limpiar slots para nueva conversación
            return [
                SlotSet("producto", None),
                SlotSet("sku", None),
                SlotSet("cantidad", None),
                SlotSet("email", None),
                SlotSet("telefono", None)
            ]
        else:
            dispatcher.utter_message(text="Lo siento, hubo un error al registrar tu cotización. Por favor intenta de nuevo.")
            return []

    def _save_to_google_sheets(self, quote_data: Dict) -> None:
        """Guarda en Google Sheets si está configurado"""
        sheet_id = os.getenv("GOOGLE_SHEET_ID")
        api_key = os.getenv("GOOGLE_API_KEY")

        if not sheet_id or not api_key:
            return

        try:
            payload = {
                "values": [[
                    quote_data["timestamp"],
                    quote_data.get("telefono", ""),
                    quote_data["producto"],
                    quote_data["sku"],
                    quote_data["cantidad"],
                    quote_data.get("email", "")
                ]]
            }

            url = f"https://sheets.googleapis.com/v4/spreadsheets/{sheet_id}/values/Cotizaciones!A1:append"
            params = {"valueInputOption": "USER_ENTERED", "key": api_key}

            response = requests.post(url, params=params, json=payload, timeout=10)
            response.raise_for_status()

        except Exception as e:
            logger.warning(f"Error saving to Google Sheets: {e}")

class ActionCheckBusinessHours(Action):
    """Verifica si está en horario laboral"""

    def name(self) -> Text:
        return "action_check_business_hours"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        now = datetime.now()

        # Horario laboral: Lunes-Viernes 9:00-18:00
        is_business_hours = (
            now.weekday() < 5 and  # Lunes-Viernes
            9 <= now.hour < 18     # 9:00-18:00
        )

        if is_business_hours:
            dispatcher.utter_message(text="¡Hola! Estamos disponibles para atenderte.")
            return [SlotSet("business_hours", True)]
        else:
            dispatcher.utter_message(text="Hola! Actualmente estamos fuera de horario laboral. Nuestro horario es de lunes a viernes de 9:00 a 18:00. ¿Te gustaría dejar un mensaje?")
            return [SlotSet("business_hours", False)]

class ActionFallback(Action):
    """Maneja casos donde el bot no entiende"""

    def name(self) -> Text:
        return "action_fallback"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        dispatcher.utter_message(text="Lo siento, no entendí tu mensaje. ¿Podrías reformularlo o elegir una opción del menú?")

        # Revertir el último mensaje del usuario para que el bot pueda intentar de nuevo
        return [UserUtteranceReverted()]

class ActionGreet(Action):
    """Saludo personalizado basado en la hora"""

    def name(self) -> Text:
        return "action_greet"

    def run(self, dispatcher: CollectingDispatcher, tracker: Tracker, domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:
        hour = datetime.now().hour

        if hour < 12:
            greeting = "¡Buenos días!"
        elif hour < 18:
            greeting = "¡Buenas tardes!"
        else:
            greeting = "¡Buenas noches!"

        dispatcher.utter_message(text=f"{greeting} Soy el asistente de AUTO-ATC. ¿En qué puedo ayudarte hoy?")
        return []

# ==========================================
# EXPORT SEAL
# ==========================================

# EXPORT_SEAL v1
# project: auto-atc
# prompt_id: rasa-actions-v3
# version: 3.0.0
# file: rasa/actions.py
# lang: py
# created_at: 2025-11-08T00:00:00Z
# author: auto-atc-setup
# origin: rasa-actions-enhanced

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
