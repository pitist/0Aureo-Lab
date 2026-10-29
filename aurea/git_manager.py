import subprocess

def ejecutar_git(comando):
    res = subprocess.run(f"git {comando}", shell=True, capture_output=True, text=True)
    return res.returncode, res.stdout.strip()

def gestionar_ciclo_git(nombre_rama="feature/ia-desarrollo", mensaje_commit="IA: Refactor y mejoras en el MVP"):
    """
    BUENA PRÁCTICA 4: Aislamiento de Ramas en Git.
    Previene la pérdida de código funcional del repositorio principal.
    """
    # 1. Asegurar que estamos en una rama de desarrollo limpia
    ejecutar_git(f"checkout -b {nombre_rama}")
    
    # 2. Agregar cambios
    ejecutar_git("add .")
    
    # 3. Validar si realmente hay cambios que commitear
    code, status = ejecutar_git("status --porcelain")
    if not status:
        print("💤 No hay cambios nuevos generados por la IA en este ciclo.")
        return False

    # 4. Hacer commit de forma automática
    code_commit, out_commit = ejecutar_git(f'commit -m "{mensaje_commit}"')
    if code_commit == 0:
        print(f"📦 Commit guardado localmente: {mensaje_commit}")
        
        # 5. Push seguro a GitHub
        code_push, _ = ejecutar_git(f"push origin {nombre_rama}")
        if code_push == 0:
            print(f"🚀 Rama '{nombre_rama}' actualizada con éxito en GitHub.")
            return True
    return False

if __name__ == "__main__":
    gestionar_ciclo_git()
