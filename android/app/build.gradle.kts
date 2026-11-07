import java.util.Base64
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

// Which backend this build is for: APP_ENV in the env file passed with
// `--dart-define-from-file` (Flutter hands those to Gradle as base64
// "dart-defines"). A staging build gets its own app id and name, so it
// installs next to the store app instead of replacing it.
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it)) }
    ?.mapNotNull { define -> define.split("=", limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] } }
    ?.toMap()
    ?: emptyMap()
val isStagingBuild = dartDefines["APP_ENV"] == "staging"
// Refuse an APK whose label and backend disagree, including a missing env file.
val expectedGateways = mapOf(
    "staging" to "https://gateway-staging-c9ff.up.railway.app",
    "production" to "https://tilomnovgateway.sparkbytekh.com",
)
if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
    val appEnv = dartDefines["APP_ENV"]
    require(appEnv in expectedGateways && dartDefines["API_BASE_URL"] == expectedGateways[appEnv]) {
        "Release builds require matching APP_ENV and API_BASE_URL. Use scripts/build_apk.ps1 -Env staging|production."
    }
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
        // Staging: also registered in Firebase (google-services.json) under this id.
        applicationId = if (isStagingBuild) "com.sparkbytekh.tilomnov.staging" else "com.sparkbytekh.tilomnov"
        manifestPlaceholders["appLabel"] = if (isStagingBuild) "Tilomnov Stage" else "Tilomnov"
        manifestPlaceholders["appIcon"] = if (isStagingBuild) "@mipmap/ic_launcher_staging" else "@mipmap/ic_launcher"
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
