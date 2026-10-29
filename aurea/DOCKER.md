# 🐳 Guía Docker - AUREA

## ¿Por qué Docker?

- ✅ **Gratis** - No cuesta nada
- ✅ **Aislado** - Entorno limpio sin contaminar tu PC
- ✅ **Reproducible** - Funciona igual en cualquier lado
- ✅ **Portátil** - Lleva todo contigo
- ✅ **Fácil** - Un comando para todo

---

## 🚀 Instalación

### Windows/Mac
Descargar [Docker Desktop](https://www.docker.com/products/docker-desktop) (gratis)

### Linux
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

---

## 📦 Usar AUREA en Docker

### Opción 1: Docker Compose (RECOMENDADO - MÁS FÁCIL)

```bash
# Construir imagen
docker-compose build

# Iniciar
docker-compose up -d

# Acceder al shell
docker-compose exec aurea /bin/bash

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

### Opción 2: Script helper (RÁPIDO)

```bash
chmod +x docker.sh

# Construir
./docker.sh build

# Iniciar
./docker.sh up

# Acceder
./docker.sh shell

# Tests
./docker.sh test

# Jupyter
./docker.sh jupyter

# Limpiar
./docker.sh clean
```

### Opción 3: Docker directo

```bash
# Construir
docker build -t aurea:latest .

# Ejecutar
docker run -it --rm \
  -v $(pwd):/workspace \
  -p 8000:8000 \
  -p 8888:8888 \
  aurea:latest /bin/bash

# Tests
docker run --rm -v $(pwd):/workspace aurea:latest pytest

# Jupyter
docker run -it --rm \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  aurea:latest jupyter lab --ip=0.0.0.0
```

---

## 🎯 Dentro del Contenedor

Una vez dentro:

```bash
# Ver estructura
ls -la

# Ejecutar tests
pytest -v

# Formatear código
black .

# Linting
flake8 .

# Jupyter Lab
jupyter lab --ip=0.0.0.0

# Python interactivo
ipython
```

---

## 📊 Puertos Disponibles

| Puerto | Servicio |
|--------|----------|
| 8000 | App principal |
| 8080 | Web Server |
| 5000 | Flask/Debug |
| 8888 | Jupyter Lab |

**Acceder desde tu PC:**
- App: http://localhost:8000
- Jupyter: http://localhost:8888

---

## 📝 Dockerfile Explicado

```dockerfile
FROM python:3.11-slim          # Imagen base ligera
WORKDIR /workspace             # Carpeta de trabajo
RUN apt-get update && ...      # Instalar dependencias
COPY requirements.txt .        # Copiar dependencias
RUN pip install ...            # Instalar Python packages
COPY . .                       # Copiar proyecto
EXPOSE 8000 8080 5000 8888    # Puertos
CMD ["/bin/bash"]              # Comando por defecto
```

---

## 💾 Volumenes (Cambios Persistentes)

Los cambios que hagas en el contenedor se guardan:

```bash
-v $(pwd):/workspace    # Tu código local se refleja en Docker
```

Esto significa:
- Editas en tu editor local
- El contenedor ve los cambios automáticamente
- NO necesitas reconstruir

---

## 🔄 Workflow típico

```bash
# 1. Construir imagen (primera vez)
./docker.sh build

# 2. Iniciar contenedor
./docker.sh up

# 3. Acceder en otra terminal
./docker.sh shell

# 4. Desarrollar normalmente
pytest
black .
flake8 .

# 5. Commit & push
git add .
git commit -m "✨ Mi cambio"
git push

# 6. Detener cuando termines
./docker.sh down
```

---

## 🎓 Ejemplos Prácticos

### Ejecutar un script Python
```bash
docker run --rm -v $(pwd):/workspace aurea:latest python src/main.py
```

### Instalar nuevo paquete
```bash
docker-compose exec aurea pip install requests
```

### Ejecutar comando específico
```bash
docker-compose exec aurea pytest tests/
```

### Limpiar cache
```bash
./docker.sh clean
```

---

## 🐛 Troubleshooting

### "Port already in use"
```bash
# Cambiar puerto en docker-compose.yml
ports:
  - "9000:8000"  # Cambiar 8000 a 9000
```

### "Permission denied"
```bash
# En Linux, dar permisos
chmod +x docker.sh
sudo usermod -aG docker $USER
```

### "Image not found"
```bash
# Reconstruir
./docker.sh build
```

---

## 💡 Tips

1. **Desarrollo = Docker Compose** (más fácil)
2. **Producción = Script helper** (más control)
3. **Tests = Docker directo** (más rápido)
4. **Jupyter = Separado** (análisis interactivo)

---

## 🌐 GitHub Container Registry

Las imágenes se suben automáticamente a:
```
ghcr.io/pitist/AUREA:latest
```

Descargar:
```bash
docker pull ghcr.io/pitist/AUREA:latest
docker run -it ghcr.io/pitist/AUREA:latest
```

---

## 📚 Recursos

- 📖 [Docker Docs](https://docs.docker.com/)
- 🐳 [Docker Hub](https://hub.docker.com/)
- 🚀 [Docker Compose](https://docs.docker.com/compose/)
- 📝 [Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**¡Listo! Ahora tienes todo containerizado y gratis! 🎉**
