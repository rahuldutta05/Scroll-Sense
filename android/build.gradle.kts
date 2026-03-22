allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (project.name == "usage_stats") {
            project.extensions.findByName("android")?.let { android ->
                try {
                    android::class.java.getMethod("compileSdkVersion", Int::class.java).invoke(android, 34)
                } catch (e: Exception) {
                    println("Could not force compileSdkVersion on \${project.name}")
                }
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
