pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

// CameraX 1.6 declara concurrent-futures, pero con Gradle 9.x el módulo de
// cámara no lo tiene en su classpath de compilación. Se añade a todos los
// módulos Android antes de evaluarlos para evitar el error de javac.
gradle.beforeProject(object : org.gradle.api.Action<org.gradle.api.Project> {
    override fun execute(project: org.gradle.api.Project) {
        project.pluginManager.withPlugin("com.android.library") {
            project.dependencies.add(
                "implementation",
                "androidx.concurrent:concurrent-futures:1.1.0",
            )
        }
    }
})
