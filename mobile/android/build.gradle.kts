import com.android.build.gradle.BaseExtension
import org.gradle.api.Action
import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    project.evaluationDependsOn(":app")
}

// Flutter plugin subprojects default to Java 8; align with :app (Java 17).
subprojects {
    if (name == "app") return@subprojects
    val alignJava17 = Action<Project> {
        extensions.findByType<BaseExtension>()?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
            )
        }
    }
    if (state.executed) {
        alignJava17.execute(this)
    } else {
        afterEvaluate(alignJava17)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
