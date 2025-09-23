plugins {
    // Google services plugin - إصدار متوافق مع Firebase BoM 32.8.1
    id("com.google.gms.google-services") version "4.4.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}


// Fix: Ensure third-party library 'image_gallery_saver' has a namespace and compiles with SDK 36
subprojects {
    if (project.name == "image_gallery_saver") {
        plugins.withId("com.android.library") {
            extensions.configure(com.android.build.gradle.LibraryExtension::class.java) {
                // Provide a deterministic namespace to satisfy AGP 8+
                namespace = "com.image_gallery_saver.generated"
                // Satisfy plugins requiring Android SDK 36
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
