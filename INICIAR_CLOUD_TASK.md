# Iniciar Tarea en la Nube - Paso a Paso

## ✅ Preparación Completada

- ✅ Scripts creados y ejecutables
- ✅ Entorno Codex creado
- ✅ Repositorio conectado

## 🚀 Iniciar Phase 1 en la Nube

### Opción A: Desde la Extensión IDE (Recomendado)

1. **Abre el Panel de Codex**:
   - En VS Code/Cursor: Busca el ícono de Codex en la barra lateral
   - O usa el comando: `Cmd+Shift+P` → "Codex: Open Panel"

2. **Selecciona tu Entorno**:
   - En el panel, busca el selector de entorno
   - Selecciona el entorno que creaste (ej: `chatbot-full-training`)

3. **Activa "Run in the cloud"**:
   - Toggle/switch que dice "Run in the cloud" → **ACTIVAR**
   - Esto cambia la ejecución de local a cloud

4. **Selecciona la Fuente**:
   - Elige: **"Off current branch"** o **"Off main"**
   - Branch: `harden/ci-and-guardrails`

5. **Escribe el Comando**:
   En el chat de Codex, escribe exactamente:

```
Ejecuta Phase 1: Training & NLU Testing

bash scripts/cloud_task_phase1.sh
```

6. **Inicia la Tarea**:
   - Haz clic en "Send" o presiona Enter
   - Codex iniciará la tarea en la nube

### Opción B: Desde la Interfaz Web

1. **Abre Codex Web**:
   - Ve a: https://chatgpt.com/codex
   - Asegúrate de estar autenticado

2. **Crea Nueva Tarea**:
   - Busca el botón "New Task" o "Create Task"
   - O inicia una conversación nueva

3. **Selecciona Entorno**:
   - En la configuración de la tarea, selecciona tu entorno

4. **Configura la Fuente**:
   - Source: "Off branch: harden/ci-and-guardrails"
   - O "Off main" si prefieres

5. **Escribe el Comando**:
   ```
   bash scripts/cloud_task_phase1.sh
   ```

6. **Inicia la Tarea**:
   - Haz clic en "Start" o "Run"

## 📋 Comando Exacto a Ejecutar

```bash
bash scripts/cloud_task_phase1.sh
```

## 📊 Qué Esperar

La tarea ejecutará:

1. ✅ Setup de Python 3.10 virtual environment
2. ✅ Instalación de dependencias (rasa, pytest, etc.)
3. ✅ Validación de datos Rasa
4. ✅ Entrenamiento del modelo (5-15 minutos)
5. ✅ Tests NLU en dataset de prueba
6. ✅ Benchmark en dataset completo
7. ✅ Generación de reportes de calidad

**Duración estimada**: 10-20 minutos

## 📁 Artifacts que se Generarán

- `models/*.tar.gz` - Modelos entrenados
- `reports/*.json` - Reportes de tests
- `reports/*.png` - Matrices de confusión y visualizaciones

## 👀 Monitorear Progreso

### En IDE:
- El panel de Codex mostrará logs en tiempo real
- Verás el progreso paso a paso
- Indicador de estado (Running/Completed/Failed)

### En Web:
- Ve a: https://chatgpt.com/codex
- Busca tu tarea en la lista
- Haz clic para ver logs detallados

## ✅ Verificar Resultados

Cuando termine, verifica:

1. **Quality Gate**:
   - Macro F1 >= 0.85 (en `reports/intent_report.json`)

2. **Modelo Generado**:
   - Archivo `.tar.gz` en `models/`

3. **Reportes**:
   - `reports/intent_report.json`
   - `reports/*.png` (visualizaciones)

## 🔄 Descargar Artifacts

### Desde IDE:
- Los artifacts se descargan automáticamente
- O usa el botón "Download Artifacts"

### Desde Web:
- Ve a la página de la tarea
- Haz clic en "Download Artifacts"
- Selecciona qué descargar (models, reports)

## 🐛 Troubleshooting

**Tarea no inicia**:
- Verifica que el entorno esté activo
- Asegúrate de que "Run in the cloud" esté activado
- Revisa que el repositorio esté conectado

**Error de permisos**:
- Verifica que el script tenga permisos de ejecución
- El script ya está configurado con `chmod +x`

**Tarea falla**:
- Revisa los logs en el panel de Codex
- Verifica que Python 3.10+ esté disponible en cloud
- Asegúrate de que `requirements.txt` esté actualizado

## 📝 Notas Importantes

- **No se requieren secrets** para Phase 1
- **Docker no es necesario** para Phase 1
- Los artifacts se guardan automáticamente
- Puedes continuar trabajando mientras se ejecuta

## 🎯 Siguiente Paso

Una vez que Phase 1 complete exitosamente:

1. Revisa los reportes generados
2. Verifica el Macro F1 score
3. Si todo está bien, puedes proceder con Phase 2 (WhatsApp testing)

---

**¿Listo?** Sigue los pasos de "Opción A" o "Opción B" arriba para iniciar la tarea.

