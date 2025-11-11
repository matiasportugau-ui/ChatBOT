# BMC Chat Interface - Documentación

Interfaz web moderna para el ChatBOT de Rasa que integra el diseño de BMC Uruguay con funcionalidades de chat, entrenamiento y analíticas.

## Características

### 🎨 Diseño
- **Diseño basado en BMC Uruguay**: Colores y estilo consistentes con el sitio web oficial
- **Layout de tres paneles**: Chat, Entrenamiento y Analíticas
- **Responsive**: Adaptable a móviles, tablets y escritorio
- **Interfaz moderna**: UI limpia y profesional

### 💬 Panel de Chat
- Conversación en tiempo real con el chatbot
- Visualización de intents y confianza
- Resaltado de entidades extraídas
- Historial de conversación
- Indicador de estado del servidor

### 🎓 Panel de Entrenamiento
- Agregar ejemplos a intents existentes
- Crear nuevos intents
- Ver ejemplos actuales
- Entrenar el modelo
- Gestión de entidades

### 📊 Panel de Analíticas
- Gráficos de confianza de intents
- Estadísticas de extracción de entidades
- Métricas de conversación
- Distribución de intents
- Visualización con Chart.js

## Requisitos Previos

1. **Servidor Rasa en ejecución**:
   ```bash
   source .venv/bin/activate
   rasa run --model models/ --enable-api --cors '*' --port 5005
   ```

2. **Training API (Opcional, para funcionalidad completa de entrenamiento)**:
   ```bash
   source .venv/bin/activate
   pip install flask flask-cors  # Si no está instalado
   python training_api.py
   ```
   Esto iniciará un servidor en `http://localhost:5006` que permite entrenar desde la interfaz web.

3. **Navegador moderno** con soporte para:
   - ES6 JavaScript
   - CSS Grid
   - Fetch API

## Instalación y Uso

### Opción 1: Servidor HTTP Simple

```bash
# Desde el directorio del proyecto
cd /Users/matias/Documents/GitHub/matiasportugau-ui/ChatBOT-full

# Iniciar servidor HTTP
python3 -m http.server 8080
```

Luego abre en tu navegador: `http://localhost:8080/web_chat_bmc.html`

### Opción 2: Servidor con Python

```bash
# Usar el script de inicio
./start_simulation.sh
# Selecciona opción 3 para abrir la interfaz web
```

### Opción 3: Abrir Directamente

Simplemente abre `web_chat_bmc.html` en tu navegador (algunas funcionalidades pueden estar limitadas por CORS).

## Estructura de Archivos

```
ChatBOT-full/
├── web_chat_bmc.html      # Estructura HTML principal
├── web_chat_bmc.css       # Estilos y diseño
├── web_chat_bmc.js        # Lógica JavaScript
├── training_api.py        # API opcional para entrenamiento desde web
├── train_chatbot.py       # Script de entrenamiento (backend)
└── README_BMC_INTERFACE.md # Esta documentación
```

## Configuración

### Cambiar URL del Servidor Rasa

Edita `web_chat_bmc.js` y modifica la constante:

```javascript
const RASA_URL = 'http://localhost:5005'; // Cambia aquí
```

### Personalizar Colores

Edita `web_chat_bmc.css` y modifica las variables CSS:

```css
:root {
    --bmc-primary: #000F9F;        /* Color principal */
    --bmc-primary-hover: #000000;  /* Color hover */
    --bmc-background: #FFFFFF;     /* Fondo */
    /* ... más colores ... */
}
```

## Uso de la Interfaz

### Panel de Chat

1. **Enviar mensaje**: Escribe en el campo de texto y presiona Enter o haz clic en el botón de envío
2. **Ver análisis**: Cada respuesta del bot muestra el intent detectado y su confianza
3. **Entidades resaltadas**: Las entidades extraídas aparecen resaltadas en amarillo

### Panel de Entrenamiento

1. **Seleccionar intent**: Elige un intent existente del dropdown
2. **Crear nuevo intent**: Haz clic en "Nuevo Intent" para crear uno nuevo
3. **Agregar ejemplo**: 
   - Escribe un ejemplo de texto
   - Para entidades, usa el formato: `[texto](entidad)`
   - Ejemplo: `quiero cotizar [remera](producto) talle [M](sku)`
4. **Ver ejemplos**: Haz clic en "Ver Ejemplos" para ver los ejemplos del intent seleccionado
5. **Entrenar modelo**: Haz clic en "Entrenar Modelo" para iniciar el entrenamiento

### Panel de Analíticas

1. **Expandir/Colapsar**: Haz clic en el botón `+`/`−` en el header del panel
2. **Ver métricas**: 
   - Total de mensajes
   - Intents detectados
   - Entidades extraídas
   - Confianza promedio
3. **Gráficos**: 
   - Gráfico de barras para confianza de intents
   - Gráfico de dona para distribución de entidades

## Integración con Backend

### Endpoints de Rasa Utilizados

- `GET /status` - Verificar estado del servidor
- `POST /webhooks/rest/webhook` - Enviar mensajes
- `POST /model/parse` - Analizar intents/entidades
- `GET /conversations/{sender_id}/tracker` - Estado de conversación

### Funcionalidades de Entrenamiento

La interfaz web puede funcionar de dos formas:

1. **Con Training API (Recomendado)**: 
   - Inicia `training_api.py` en el puerto 5006
   - Permite agregar ejemplos y entrenar directamente desde la web
   - Carga intents y ejemplos reales desde los archivos NLU

2. **Sin Training API (Modo básico)**:
   - Funciona con valores por defecto
   - Muestra instrucciones para usar `train_chatbot.py` directamente
   - Todas las funcionalidades de chat y analíticas funcionan normalmente

Para iniciar el Training API:
```bash
source .venv/bin/activate
pip install flask flask-cors  # Solo la primera vez
python training_api.py
```

## Personalización

### Agregar Nuevos Paneles

1. Agrega el HTML en `web_chat_bmc.html`
2. Agrega estilos en `web_chat_bmc.css`
3. Agrega funcionalidad en `web_chat_bmc.js`
4. Actualiza la navegación en el header

### Modificar Layout

El layout usa CSS Grid. Modifica `.main-container` en `web_chat_bmc.css`:

```css
.main-container {
    grid-template-columns: 1fr 350px;  /* Ajusta columnas */
    grid-template-rows: 1fr auto;      /* Ajusta filas */
}
```

## Solución de Problemas

### El servidor no se conecta

1. Verifica que Rasa esté corriendo:
   ```bash
   curl http://localhost:5005/status
   ```

2. Verifica que CORS esté habilitado:
   ```bash
   rasa run --enable-api --cors '*' --port 5005
   ```

3. Revisa la consola del navegador (F12) para errores

### Los gráficos no se muestran

- Verifica que Chart.js esté cargado (CDN en el HTML)
- Revisa la consola del navegador para errores de JavaScript

### El entrenamiento no funciona

- Actualmente es una simulación
- Para funcionalidad completa, integra con `train_chatbot.py` o crea endpoints de API

## Mejoras Futuras

- [ ] Integración completa con `train_chatbot.py`
- [ ] Exportar conversaciones a JSON/CSV
- [ ] Modo oscuro/claro
- [ ] Búsqueda en historial de conversaciones
- [ ] Soporte para múltiples idiomas
- [ ] Notificaciones en tiempo real
- [ ] Integración con base de datos para persistencia
  - ✅ **MongoDB Atlas Setup**: Ver [MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md) para configuración

## Base de Datos

### MongoDB Atlas

Para usar MongoDB Atlas (recomendado para producción), consulta las guías:

📖 **[MONGODB_ATLAS_SETUP.md](MONGODB_ATLAS_SETUP.md)** - Configuración de conexión
🔐 **[MONGODB_CREDENTIALS.md](MONGODB_CREDENTIALS.md)** - Gestión segura de credenciales

**Guías incluyen:**
- Configuración de IP whitelist
- Creación de usuarios de base de datos
- Obtención de connection string
- **API Keys seguras** (ya configuradas en `.env`)
- Configuración en la aplicación
- Solución de problemas comunes

### Prueba de Conexión

Para verificar tu conexión a MongoDB Atlas:

```bash
python test_mongodb_atlas.py
```

O configura la variable de entorno:

```bash
export MONGODB_URI="mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/bmc_chat"
python test_mongodb_atlas.py
```

## Tecnologías Utilizadas

- **HTML5**: Estructura semántica
- **CSS3**: Grid, Flexbox, Variables CSS
- **JavaScript ES6+**: Vanilla JS (sin frameworks)
- **Chart.js**: Visualización de datos
- **Fetch API**: Comunicación con Rasa

## Compatibilidad

- ✅ Chrome/Edge (últimas versiones)
- ✅ Firefox (últimas versiones)
- ✅ Safari (últimas versiones)
- ⚠️ Internet Explorer (no soportado)

## Licencia

Este proyecto es parte del ecosistema ChatBOT-full.

## Soporte

Para problemas o preguntas:
1. Revisa esta documentación
2. Verifica los logs de la consola del navegador
3. Verifica que el servidor Rasa esté funcionando correctamente

---

**Desarrollado para BMC Uruguay** 🇺🇾

