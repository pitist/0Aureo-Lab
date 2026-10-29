import os
import subprocess
import time
from openai import OpenAI  # O la librería del modelo que prefieras

# 1. Inicializar cliente y entorno
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
REPO_PATH = "./"
MAX_INTENTOS = 20  # Límite por ciclo para evitar bucles infinitos de coste

def ejecutar_comando(comando):
    """Ejecuta un comando en la consola del sistema y devuelve el resultado."""
    resultado = subprocess.run(comando, shell=True, capture_output=True, text=True)
    return resultado.returncode, resultado.stdout, resultado.stderr

def leer_codigo_proyecto():
    """Lee los archivos clave del proyecto para darle contexto a la IA."""
    contexto = ""
    # Extensiones de archivos que tu IA va a analizar y editar
    extensiones_validas = ('.js', '.json', '.py', '.html', '.env-example', '.md')
    
    for raiz, _, archivos in os.walk(REPO_PATH):
        if "node_modules" in raiz or ".git" in raiz:
            continue
        for archivo in archivos:
            if archivo.endswith(extensiones_validas):
                ruta_completa = os.path.join(raiz, archivo)
                with open(ruta_completa, 'r', encoding='utf-8') as f:
                    contexto += f"\n\n--- ARCHIVO: {ruta_completa} ---\n"
                    contexto += f.read()
    return contexto

def guardar_codigo_ia(respuesta_ia):
    """Procesa la respuesta de la IA y sobreescribe o crea los archivos correspondientes."""
    # Tu IA debe devolver los archivos en un formato fácil de parsear, por ejemplo estructurado con marcas.
    # Esta función busca bloques de código destinados a archivos específicos.
    partes = respuesta_ia.split("=== INICIO_ARCHIVO: ")
    for parte in partes[1:]:
        lineas = parte.split("\n")
        ruta_archivo = lineas[0].strip()
        contenido = "\n".join(lineas[1:]).split("=== FIN_ARCHIVO")[0].strip()
        
        # Crear directorios si no existen y escribir el archivo
        os.makedirs(os.path.dirname(ruta_archivo), exist_ok=True)
        with open(ruta_archivo, "w", encoding="utf-8") as f:
            f.write(contenido)
        print(f"📝 Archivo modificado por IA: {ruta_archivo}")

def bucle_autonomo():
    objetivo_monetizacion = (
        "Crea un MVP funcional de un micro-SaaS que use Stripe para cobrar suscripciones. "
        "Genera el servidor, la lógica de monetización, la interfaz de usuario y los tests unitarios. "
        "Debes estructurar tu respuesta incluyendo los archivos de la siguiente forma exacta:\n"
        "=== INICIO_ARCHIVO: ruta/del/archivo.ext\ncontenido\n=== FIN_ARCHIVO ==="
    )

    for intento in range(1, MAX_INTENTOS + 1):
        print(f"\n🔄 [Ciclo {intento}] Analizando estado del repositorio...")
        
        # 1. Obtener contexto actual y estado de los tests
        codigo_actual = leer_codigo_proyecto()
        codigo_retorno, stdout_test, stderr_test = ejecutar_comando("npm test")
        
        estado_tests = "TODOS LOS TESTS PASAN ✅" if codigo_retorno == 0 else f"FALLO EN TESTS ❌:\n{stdout_test}\n{stderr_test}"
        print(f"Estado actual: {estado_tests}")

        # Si los tests pasan y ya existe el sistema de cobro, el objetivo está cumplido
        if codigo_retorno == 0 and "stripe" in codigo_actual.lower() and intento > 2:
            print("💰 ¡Producto monetizable y estable alcanzado! Saliendo del bucle.")
            ejecutar_comando("git add . && git commit -m 'IA: Producto monetizable completado con éxito' && git push origin main")
            break

        # 2. Construir el Prompt para tu IA
        prompt = f"""
        Objetivo Principal: {objetivo_monetizacion}
        
        Estado actual del código en el repositorio:
        {codigo_actual}
        
        Resultado de las pruebas de ejecución:
        {estado_tests}
        
        Analiza el fallo o la falta de características de monetización. Modifica o crea los archivos necesarios para avanzar hacia el objetivo. Devuelve SOLO los archivos modificados con la estructura solicitada.
        """

        print("🤖 Enviando contexto a la API de la IA...")
        # 3. Llamada directa a tu modelo
        respuesta = client.chat.completions.create(
            model="gpt-4o", # O el modelo que estés pagando directamente
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2
        )
        
        respuesta_texto = respuesta.choices[0].message.content

        # 4. Aplicar los cambios generados por la IA de forma nativa
        guardar_codigo_ia(respuesta_texto)
        
        # 5. Commit de control local para registrar el avance de este ciclo
        ejecutar_comando(f"git add . && git commit -m 'IA: Iteración del bucle autónomo ciclo {intento}'")
        
        time.sleep(2) # Pausa de cortesía para el sistema de archivos

if __name__ == "__main__":
    bucle_autonomo()
