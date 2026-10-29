# AUREA

📱 **Aplicación Android**

## Descripción
Proyecto Android en desarrollo.

## Estado de auditoría
[![Audit Status](https://github.com/pitist/AUREA/actions/workflows/audit.yml/badge.svg)](https://github.com/pitist/AUREA/actions/workflows/audit.yml)

## Características
- ✅ Proyecto Android (Kotlin/Java)
- ✅ Gradle build
- ✅ Auditoría automática con `audit.yml`

## Estructura
```
app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   └── res/
│   └── test/
├── build.gradle
└── settings.gradle
```

## Ejecución local
```bash
./gradlew build
./gradlew installDebug
```

## Auditoría
El repositorio incluye un workflow de auditoría que ejecuta automáticamente 59 reglas de calidad Android.

---
*Repositorio mantenido con el sistema android-toolchain.*