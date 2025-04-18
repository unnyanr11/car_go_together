import java.util.Properties  

plugins {  
    id("com.android.application")  
    id("kotlin-android")  
    id("dev.flutter.flutter-gradle-plugin")  
    // Add the Google services Gradle plugin  
    id("com.google.gms.google-services")  
}  

// Your existing properties code  
fun getLocalProperty(key: String, projectProperties: Properties): String {  
    return projectProperties.getProperty(key) ?: ""  
}  

val localProperties = Properties()  
val localPropertiesFile = rootProject.file("local.properties")  
if (localPropertiesFile.exists()) {  
    localPropertiesFile.reader().use { reader ->  
        localProperties.load(reader)  
    }  
}  

val flutterVersionCode: String = getLocalProperty("flutter.versionCode", localProperties).takeIf { it.isNotEmpty() } ?: "1"  
val flutterVersionName: String = getLocalProperty("flutter.versionName", localProperties).takeIf { it.isNotEmpty() } ?: "1.0"  

android {  
    // Your existing android configuration  
    namespace = "com.example.car_go_together"  
    compileSdk = flutter.compileSdkVersion  
    ndkVersion = "27.0.12077973"  

    compileOptions {  
        isCoreLibraryDesugaringEnabled = true  
        sourceCompatibility = JavaVersion.VERSION_17  
        targetCompatibility = JavaVersion.VERSION_17  
    }  

    kotlinOptions {  
        jvmTarget = JavaVersion.VERSION_17.toString()  
    }  

    defaultConfig {  
        applicationId = "com.example.car_go_together"  
        minSdk = 24
        versionCode = flutterVersionCode.toInt()  
        versionName = flutterVersionName  
        multiDexEnabled = true  
    }  

    buildTypes {  
        release {  
            signingConfig = signingConfigs.getByName("debug")  
        }  
    }  
}  

flutter {  
    source = ".."  
}  

dependencies {  
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:${rootProject.extra["kotlin_version"]}")  
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  
    
    // Import the Firebase BoM  
    implementation(platform("com.google.firebase:firebase-bom:31.5.0"))  
    
    // Add Firebase products (without version numbers)  
    // Note: Flutter plugins usually handle this, but these ensure native compatibility  
    implementation("com.google.firebase:firebase-analytics")  
}  