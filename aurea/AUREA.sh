#!/bin/bash

# Detener el script si ocurre algún error
set -e

# 1. Cargar variables de entorno si existen
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    echo "⚠️ Nota: Ejecutando sin archivo .env local."
fi

echo "✨ [AUREA] Iniciando empaquetado y envío a GitHub..."

# 2. Obtener la rama actual de Git
CURRENT_BRANCH=$(git branch --show-current)
echo "🌿 [AUREA] Rama actual: $CURRENT_BRANCH"

# 3. Empaquetar todo el repositorio para la IA
echo "📦 [AUREA] Ejecutando Repomix de forma automática..."
npx repomix@latest --style xml --ignore ".env,node_modules/,dist/,*.log"

# 4. Enviar los cambios a GitHub (Esto activará el deploy automático en Render)
echo "💾 [AUREA] Guardando cambios en Git..."
git add .

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
git commit -m "AUREA Auto-Pack & Deploy: $TIMESTAMP" || echo "⚠️ [AUREA] No hay cambios nuevos en el código."

echo "📤 [AUREA] Subiendo a GitHub para activar el despliegue automático..."
git push origin "$CURRENT_BRANCH"

echo "🎉 [AUREA] ¡Código subido con éxito!"
echo "🚀 Render está leyendo tu repositorio en este momento y comenzará el despliegue automáticamente."
