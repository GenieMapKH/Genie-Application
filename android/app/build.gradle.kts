import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // No kotlin-android here: the Flutter Gradle Plugin applies it (android.builtInKotlin=false).
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (never committed) points at the keystore.
// Without it a local release build falls back to the debug key, so
// `flutter run --release` keeps working. CI refuses to release without the
// real key (see .github/workflows). Play Store uploads need the real key.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// Google Maps key for Android: the MAPS_API_KEY environment variable (CI's
// secret), else MAPS_API_KEY in android/local.properties (never committed).
// Restrict it in Google Cloud to this app's package name and signing
// certificate; the web build uses a separate key restricted to its sites.
val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String = System.getenv("MAPS_API_KEY")
    ?: localProperties.getProperty("MAPS_API_KEY")
    ?: ""
if (mapsApiKey.isEmpty()) {
    logger.warn("MAPS_API_KEY is not set: the map will stay blank.")
}

android {
    namespace = "com.sparkbytekh.tilomnov"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // The store listing is tied to this id: it cannot change after release.
        applicationId = "com.sparkbytekh.tilomnov"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Optional: APK_EXPORT_DIR in android/local.properties (never committed) is a
// folder every `flutter build apk` also copies its APKs into. Unset, nothing
// is copied (CI and other machines are unaffected).
val apkExportDir: String? = localProperties.getProperty("APK_EXPORT_DIR")
if (!apkExportDir.isNullOrBlank()) {
    val exportApks = tasks.register<Copy>("exportApks") {
        from(layout.buildDirectory.dir("outputs/flutter-apk")) { include("*.apk") }
        into(apkExportDir)
    }
    // The Flutter plugin creates the assemble tasks after this script runs.
    afterEvaluate {
        listOf("assembleDebug", "assembleProfile", "assembleRelease").forEach { name ->
            tasks.findByName(name)?.finalizedBy(exportApks)
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
