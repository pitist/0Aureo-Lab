plugins {
    id("com.android.application") version "7.4.2"
}

android {
    namespace = "com.aurea.app"
    compileSdk = 33

    defaultConfig {
        applicationId = "com.aurea.app"
        minSdk = 21
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.5.1")
}
