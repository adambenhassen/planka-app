import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials; absent in local dev checkouts (gitignored),
// present in CI via secrets. Missing file → debug-signed release build.
val keyProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}

android {
    namespace = "app.planka.planka_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.planka.planka_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // `github` is the sideloaded build (in-app updater, APK on the GitHub
    // release); `store` is what Google Play and F-Droid get — same
    // applicationId, but without the self-install permission, since both
    // stores forbid an app that updates itself. The store manifest strips the
    // permission; the Dart side is compiled out by the define the check below
    // enforces.
    flavorDimensions += "distribution"
    productFlavors {
        create("github") { dimension = "distribution" }
        create("store") { dimension = "distribution" }
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Stable release key so sideloaded updates install over the
            // previous version; debug key only when key.properties is absent.
            signingConfig = if (keyProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// No artifact bound for a store may contain a reachable self-update path.
// Stripping REQUEST_INSTALL_PACKAGES in the store manifest only removes the
// permission — without the define, the Dart updater is still compiled in and
// still downloads an APK, and the runtime `com.android.vending` guard covers
// Play installs but not F-Droid. Holding that invariant must not depend on a
// build command remembering a flag, so a store build without the define fails
// here rather than shipping quietly.
//
// `flutter build --dart-define=K=V` reaches Gradle as `-Pdart-defines=`, a
// comma-separated list of base64-encoded `K=V` pairs.
val buildsStoreFlavor = gradle.startParameter.taskNames.any { it.contains("Store") }
if (buildsStoreFlavor) {
    val defines = (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.filter { it.isNotBlank() }
        ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        ?: emptyList()
    if (!defines.contains("ENABLE_IN_APP_UPDATER=false")) {
        throw GradleException(
            "The store flavor must be built with " +
                "--dart-define=ENABLE_IN_APP_UPDATER=false. Google Play and " +
                "F-Droid both reject an app that installs its own updates, and " +
                "without this the updater is compiled into the bundle."
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
