import os
import subprocess
import json
from openai import OpenAI

# BUENA PRÁCTICA 1: Cargar variables de entorno de forma segura
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("❌ ERROR: La variable OPENAI_API_KEY no está configurada.")

client = OpenAI(api_key=OPENAI_API_KEY)

def ejecutar_comando(comando):
    """Ejecuta comandos de consola de forma segura capturando salidas."""
    resultado = subprocess.run(comando, shell=True, capture_output=True, text=True)
    return resultado.returncode, resultado.stdout, resultado.stderr

def validar_repositorio():
    """
    BUENA PRÁCTICA 2: El 'Linter' y los Tests actúan como árbitros.
    Evita que la IA suba código roto o con mala sintaxis.
    """
    print("🔍 Validando sintaxis del código con Ruff...")
    # Asegúrate de instalar ruff: pip install ruff
    code_lint, out_lint, _ = ejecutar_comando("ruff check .")
    
    print("🧪 Ejecutando pruebas unitarias...")
    # Asegúrate de instalar pytest: pip install pytest
    code_test, out_test, err_test = ejecutar_comando("pytest")
    
    if code_lint != 0:
        return False, f"Error de estilo/sintaxis:\n{out_lint}"
    if code_test != 0:
        return False, f"Pruebas fallidas:\n{out_test}\n{err_test}"
    
    return True, "Todo correcto"

def iterar_bucle_ia(prompt_objetivo):
    """Ejecuta una iteración del desarrollo autónomo."""
    status_ok, detalle = validar_repositorio()
    
    # BUENA PRÁCTICA 3: Enviar el feedback exacto del error a la IA si algo falla
    if not status_ok:
        print("⚠️ El repositorio actual tiene errores. Forzando a la IA a reparar...")
        prompt_ia = f"El código actual falla con el siguiente error:\n{detalle}\nREPARALO."
    else:
        print("✅ Código base estable. Solicitando nueva funcionalidad monetizable...")
        prompt_ia = prompt_objetivo

    # Llamada directa a la API (puedes cambiar a gpt-4o o el modelo que desees)
    respuesta = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "Eres un ingeniero experto. Devuelves código limpio en formato JSON estructurado."},
            {"role": "user", "content": prompt_ia}
        ],
        temperature=0.1 # Temperatura baja para código más predecible y exacto
    )
    
    return respuesta.choices.message.content

if __name__ == "__main__":
    # Ejemplo de uso en una iteración
    objetivo = "Añade un endpoint en Flask/FastAPI que procese un webhook de Stripe para compras exitosas."
    resultado_ia = iterar_bucle_ia(objetivo)
    print("🤖 Respuesta de la IA recibida.")
