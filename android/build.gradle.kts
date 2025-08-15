// Project-level build.gradle (Groovy)
// Merged to include Google Services and repository settings,
// plus custom build directory layout and clean task.

buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: relocate build directories (non-standard but matches your snippet).
// If you don't need this, you can remove this whole section.

def newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects { proj ->
    def newSubprojectBuildDir = newBuildDir.dir(proj.name)
    proj.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
// (Flutter templates usually use `delete rootProject.buildDir`,
// but this version matches the Provider API of Gradle 8.)
tasks.register('clean', Delete) {
    delete rootProject.layout.buildDirectory
}