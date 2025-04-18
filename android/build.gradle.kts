import org.gradle.api.file.Directory

// Top-level build file where you can add configuration options common to all sub-projects/modules.  
buildscript {  
    // Update Kotlin version to 2.0.0 which is compatible with Firebase dependencies  
    val kotlin_version by extra("1.9.22")  

    repositories {  
        google()  
        mavenCentral()  
    }  

    dependencies {  
        classpath("com.android.tools.build:gradle:8.2.0")  
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")  
    }  
}  

plugins {  
    // Add the dependency for the Google services Gradle plugin  
    id("com.google.gms.google-services") version "4.3.15" apply false  
}  

allprojects {  
    repositories {  
        google()  
        mavenCentral()  
    }  
}  

// The rest of your file remains the same  
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()  
rootProject.layout.buildDirectory.value(newBuildDir)  

subprojects {  
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)  
    project.layout.buildDirectory.value(newSubprojectBuildDir)  
}  
subprojects {  
    project.evaluationDependsOn(":app")  
}  

tasks.register<Delete>("clean") {  
    delete(rootProject.layout.buildDirectory)  
}