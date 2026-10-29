import os
import subprocess
import time
import sys
from openai import OpenAI

# 1. Verificar credenciales antes de arrancar
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    print("❌ ERROR CRÍTICO: No se detectó la variable OPENAI_API_KEY en tu entorno.", file=sys.stderr)
    print("Por favor, ejecuta en tu terminal: export OPENAI_API_KEY='tu_clave'", file=sys.stderr)
    sys.exit(1)

client = OpenAI(api_key=OPENAI_API_KEY)

def log_verde(mensaje):
    """Imprime mensajes en verde brillante para identificar avances del agente."""
    print(f"\033[92m🤖 [AGENTE]: {mensaje}\033[0m", flush=True)

def log_info(mensaje):
    """Imprime logs informativos estándar de forma inmediata."""
    print(f"ℹ️ {mensaje}", flush=True)

def ejecutar_comando_en_vivo(comando):
    """Ejecuta un comando y muestra su salida en la pantalla en tiempo real."""
    log_info(f"Ejecutando comando: {comando}")
    # Ejecuta capturando la salida para que el usuario la vea pasar en su consola
    proceso = subprocess.Popen(comando, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    
    salida_completa = ""
    while True:
        linea = proceso.stdout.readline()
        if not linea and proceso.poll() is not None:
            break
        if linea:
            print(f"  > {linea.strip()}", flush=True)
            salida_completa += linea
            
    return proceso.poll(), salida_completa

def comprobar_git():
    """Verifica si la carpeta actual es un repositorio git."""
    codigo, _ = ejecutar_comando_en_vivo("git status")
    if codigo != 0:
        log_verde("El directorio no tiene Git iniciado. Inicializando repositorio...")
        ejecutar_comando_en_vivo("git init && git add . && git commit -m 'Initial commit'")

def ejecutar_bucle():
    comprobar_git()
    
    objetivo = "Crea un backend mínimo monetizable en Python usando FastAPI con una ruta '/checkout' simulada."
    
    for ciclo in range(1, 5): # Limitado a 4 ciclos para probar visualmente
        log_verde(f"=== INICIANDO CICLO DE TRABAJO {ciclo} ===")
        
        # Simulación de test para ver el flujo en pantalla
        log_info("Paso 1: Evaluando estado del código con Pytest...")
        codigo_test, salida_test = ejecutar_comando_en_vivo("pytest")
        
        estado_contexto = "Los tests actuales pasan." if codigo_test == 0 else f"Errores encontrados:\n{salida_test}"
        
        log_info("Paso 2: Enviando código y estado a la API de OpenAI...")
        
        # Llamada con streaming deshabilitado temporalmente pero con avisos visuales claros
        try:
            respuesta = client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "Eres un programador autónomo. Devuelve código funcional."},
                    {"role": "user", "content": f"Objetivo: {objetivo}. Estado actual: {estado_contexto}. Genera el código correspondiente."}
                ],
                temperature=0.2
            )
            log_verde("¡La IA ha respondido con éxito!")
            texto_ia = respuesta.choices.message.content
            
            # Mostrar un extracto de lo que pensó la IA para comprobar que trabaja
            log_info(f"Extracto de la propuesta de la IA:\n{texto_ia[:200]}...\n")
            
        except Exception as e:
            print(f"❌ Error al conectar con OpenAI: {e}", flush=True)
            break
            
        log_info("Paso 3: Guardando cambios en Git...")
        ejecutar_comando_en_vivo(f"git add . && git commit -m 'IA: Progreso ciclo {ciclo}'")
        
        log_info("Esperando 5 segundos para el siguiente ciclo...\n")
        time.sleep(5)

if __name__ == "__main__":
    log_info("Arrancando el motor autónomo...")
    ejecutar_bucle()
