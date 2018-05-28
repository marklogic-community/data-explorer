package data_explorer;

import org.gradle.tooling.BuildLauncher;
import org.gradle.tooling.GradleConnector;
import org.gradle.tooling.ProjectConnection;

import java.io.File;

public class GradleTaskRunner {

  private GradleConnector connector = GradleConnector.newConnector();

  public GradleTaskRunner() {
    connector.forProjectDirectory(new File("."));
  }

  public void run(String taskName) {
    System.out.println("Running gradle task: " + taskName);
    ProjectConnection connection = connector.connect();
    BuildLauncher build = connection.newBuild();
    build.forTasks(taskName);
    build.run();
    connection.close();
  }
}