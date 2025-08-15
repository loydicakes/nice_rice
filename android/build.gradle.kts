// android/build.gradle (Groovy)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.6.0'
        classpath 'com.google.gms:google-services:4.4.2'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// (Optional) If you had this block, you can keep it in Groovy:
subprojects { proj ->
    // custom build dir logic (only if you really need it)
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}
