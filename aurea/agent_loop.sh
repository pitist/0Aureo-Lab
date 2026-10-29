#!/bin/bash

# 1. Cargar configuración
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    echo "Falta el archivo .env"
    exit 1
fi

echo "🤖 Iniciando Agente de IA en bucle de desarrollo..."

# OBJETIVO PRINCIPAL: Define aquí qué producto monetizable quieres construir
OBJETIVO="Crear una plataforma SaaS MVP de micro-facturación con pasarela de pago Stripe integrada. Crear endpoints, interfaz básica y tests automatizados."

# 2. Ejecutar Aider en modo autónomo/bucle
# --auto-commit: Hace un commit de git automáticamente si el código compila
# --test: Corre tus tests. Si fallan, la IA vuelve a editar el código en bucle hasta que pasen.
aider --model anthropic/claude-3-5-sonnet \
      --message "$OBJETIVO" \
      --test "npm test" \
      --auto-commit \
      --yes

# 3. Validar si el bucle local terminó con éxito
if [ $? -eq 0 ]; then
    echo "✅ El Agente logró que todos los tests pasaran. Subiendo cambios a producción..."
    git push origin main
    
    # 4. Forzar actualización en tu servicio de Render
    echo "🚀 Desplegando en Render ($RENDER_SERVICE_ID)..."
    curl -X POST "https://render.com" \
         -H "Authorization: Bearer $RENDER_API_KEY" \
         -H "Accept: application/json"
else
    echo "⚠️ El bucle falló o requiere intervención humana en los tests."
fi
