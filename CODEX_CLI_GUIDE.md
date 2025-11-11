# Codex CLI - Guía de Uso

## Instalación Completada

✅ **Codex CLI instalado**: versión `0.25.0`

```bash
npm i -g @openai/codex
```

## Tipo de CLI

Este CLI es un **CLI interactivo** para ejecutar Codex localmente, no para gestionar tareas en la nube directamente. Para tareas en la nube, usa la **extensión IDE** o la **interfaz web**.

## Comandos Disponibles

### Verificar Instalación

```bash
codex --version
# Output: codex-cli 0.25.0
```

### Autenticación

```bash
codex login
```

Esto autentica el CLI para uso local.

### Ejecutar Codex Interactivamente

```bash
# Modo interactivo (por defecto)
codex

# Con prompt inicial
codex "Ejecuta el script de training"

# Con directorio específico
codex -C /ruta/al/proyecto "Comando a ejecutar"
```

### Ejecutar Comando Específico

```bash
# Ejecutar script directamente
codex exec "bash scripts/cloud_task_phase1.sh"

# Con opciones de sandbox
codex exec --sandbox workspace-write "bash scripts/cloud_task_phase1.sh"
```

### Opciones Útiles

```bash
# Modo automático (menos confirmaciones)
codex --full-auto "bash scripts/cloud_task_phase1.sh"

# Modo read-only (solo lectura)
codex --sandbox read-only "ls -la"

# Con búsqueda web habilitada
codex --search "Buscar información sobre Rasa"
```

## Ejemplo: Ejecutar Phase 1 Localmente

```bash
# 1. Autenticarse
codex login

# 2. Ejecutar Phase 1 localmente (no en la nube)
codex exec --sandbox workspace-write "bash scripts/cloud_task_phase1.sh"

# O modo interactivo
codex "Ejecuta el script cloud_task_phase1.sh para training y testing"
```

## Para Tareas en la Nube

**El CLI no gestiona tareas en la nube directamente**. Para eso:

1. **Usa la Extensión IDE** (recomendado):
   - Panel de Codex en VS Code/Cursor
   - Selecciona "Run in the cloud"
   - Ejecuta el comando

2. **Usa la Interfaz Web**:
   - https://chatgpt.com/codex
   - Crea tarea desde la web UI

3. **Usa el CLI en modo interactivo para preparar**:
   ```bash
   codex "Prepara el script para ejecutar en la nube: bash scripts/cloud_task_phase1.sh"
   ```

## Ventajas del CLI Local

1. **Ejecución Local**: Prueba scripts antes de enviarlos a la nube
2. **Interactivo**: Conversación con Codex desde terminal
3. **Sandboxing**: Control de permisos de ejecución
4. **Rápido**: No requiere configuración de entorno en la nube

## Comparación: CLI Local vs Cloud Tasks

| Característica | CLI Local | Cloud Tasks (IDE/Web) |
|---------------|----------|----------------------|
| Ejecución | Local (tu máquina) | En la nube |
| Recursos | Limitados por tu PC | Recursos de Codex |
| Docker | Requiere Docker local | Disponible en cloud |
| Autenticación | `codex login` | Extensión IDE / Web |
| Monitoreo | Terminal output | Panel IDE / Web UI |
| Artifacts | En tu máquina | Descargables desde web |

## Cuándo Usar Cada Opción

**Usa CLI Local cuando**:
- Quieres probar scripts rápidamente
- No necesitas Docker o servicios externos
- Prefieres ejecución inmediata
- Tienes todos los recursos locales

**Usa Cloud Tasks cuando**:
- Necesitas Docker y servicios (Phase 2)
- Quieres recursos dedicados
- Prefieres no usar recursos locales
- Necesitas ejecución en entorno aislado

## Próximos Pasos

### Opción 1: Ejecutar Localmente con CLI

```bash
# 1. Autenticarse
codex login

# 2. Ejecutar Phase 1 localmente
codex exec --sandbox workspace-write "bash scripts/cloud_task_phase1.sh"
```

### Opción 2: Ejecutar en la Nube (Recomendado)

1. **Usa la Extensión IDE**:
   - Abre panel de Codex
   - Selecciona "Run in the cloud"
   - Ejecuta: `bash scripts/cloud_task_phase1.sh`

2. **O usa la Web UI**:
   - Ve a https://chatgpt.com/codex
   - Crea nueva tarea
   - Ejecuta el script

## Referencia Rápida

```bash
# Autenticación
codex login
codex login status

# Ejecución
codex "prompt aquí"
codex exec "comando"
codex exec --sandbox workspace-write "script.sh"
codex --full-auto "comando"

# Configuración
codex -C /ruta/al/proyecto "comando"
codex -m o3 "comando"
codex --search "buscar algo"

# Ayuda
codex --help
codex exec --help
codex login --help
```

## Troubleshooting

**Error de autenticación**:
```bash
codex login  # Re-autenticar
codex login status  # Verificar estado
```

**Script no ejecuta**:
```bash
# Usar sandbox más permisivo
codex exec --sandbox workspace-write "script.sh"

# O modo automático
codex --full-auto "script.sh"
```

**Permisos insuficientes**:
```bash
# Verificar permisos del script
chmod +x scripts/cloud_task_phase1.sh

# Ejecutar con sandbox apropiado
codex exec --sandbox workspace-write "bash scripts/cloud_task_phase1.sh"
```

