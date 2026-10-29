# Makefile para AUREA

.PHONY: help install test lint format clean all dev docker-build docker-apk docker-compose-up docker-clean

help:
	@echo "🚀 AUREA Makefile Commands"
	@echo "==========================="
	@echo "make install         - Instalar dependencias"
	@echo "make test            - Ejecutar tests"
	@echo "make lint            - Ejecutar linters"
	@echo "make format          - Formatear código"
	@echo "make clean           - Limpiar caché"
	@echo "make all             - Instalar, formatear y testar"
	@echo "make dev             - Instalar modo desarrollo"
	@echo ""
	@echo "🐳 Docker + Android Commands"
	@echo "=============================="
	@echo "make docker-build    - Construir imagen Docker"
	@echo "make docker-apk      - Generar APK con Docker (assembleRelease)"
	@echo "make docker-debug    - Generar APK debug con Docker"
	@echo "make docker-compose-up - Iniciar servicio builder con docker-compose"
	@echo "make docker-clean    - Limpiar imágenes y volúmenes Docker"

install:
	pip install -r requirements.txt

test:
	pytest -v --cov=src --cov-report=term-missing

lint:
	flake8 src/ tests/
	pylint src/

format:
	black src/ tests/

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache/ .coverage htmlcov/

all: install format test

dev: install
	pip install -q black flake8 pylint pytest-cov jupyter ipython

# Docker + Android targets
docker-build:
	@echo "🐳 Construyendo imagen Docker..."
	docker build -t aurea-android-builder:latest .

docker-apk: docker-build
	@echo "📦 Generando APK (release)..."
	chmod +x docker.sh
	./docker.sh assembleRelease

docker-debug: docker-build
	@echo "📦 Generando APK (debug)..."
	chmod +x docker.sh
	./docker.sh assembleDebug

docker-compose-up:
	@echo "🐳 Iniciando docker-compose..."
	docker-compose up -d builder

docker-clean:
	@echo "🧹 Limpiando Docker..."
	docker-compose down -v
	docker rmi aurea-android-builder:latest || true
	rm -rf build/outputs/apks/
