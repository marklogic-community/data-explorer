package data_explorer.gradle_tasks;

import data_explorer.AbstractTest;
import data_explorer.GradleTaskRunner;

import org.apache.commons.io.FileUtils;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

import static javax.ws.rs.core.Response.Status.OK;


/**
 * ImportExportQueriesViews
 */

public class ImportExportQueriesViews extends AbstractTest {

  private GradleTaskRunner task = new GradleTaskRunner();
  private  String label;
  private boolean dataFolderExists;

  @Before
  public void createTestData() {
    dataFolderExists = new File("data").exists();
    createTestQueries();
  }

  @After
  public void cleanup() throws IOException {
    // Delete the data folder if we created it
    if(!dataFolderExists) {
      FileUtils.deleteDirectory(new File("data"));
    }
    // Delete the test queries
    deleteQuery("/default_ns:farmersMarket", label);
  }


  @Test
  public void ImportExportQueriesAndViewsTest() {
    assertFalse("data folder already exists. Remove the folder and rerun the test.", dataFolderExists);

    assertTrue("Unable to create query.", findQueryByLabel(label) == 1);

    // Run the ExportQueriesAndViews gradle task
    task.run("ExportQueriesAndViews");

    // Check for the test query xml
    // TODO: Check for multiple queries/views. Possibly parse the xml and validate or verify the contents.
    assertTrue("Exported query not found.", new File("data/export/adhoc/default_nsfarmersMarket/forms-queries/" + label + ".xml").exists());

    // Delete our query
    deleteQuery("/default_ns:farmersMarket", label);

    assertTrue("Unable to delete query.", findQueryByLabel(label) == 0);

    // Run the ImportQueriesAndViews gradle task
    task.run("ImportQueriesAndViews");

    System.out.println(findQueryByLabel(label));
    assertTrue("Exported query was not imported.", findQueryByLabel(label) == 1);

  }

  protected void createTestQueries() {
    // TODO: The endpoint really should be a post of JSON data. This will be addressed in issue #90
    // https://github.com/marklogic-community/data-explorer/issues/90
    String createQueryRequest = getResource("newQuery1.txt");

    // Create a random query/bookmark name
    UUID uuid = UUID.randomUUID();
    label = "Test_Query-" + uuid.toString();

    // Create the test query
    // TODO: Should create mutliple different queries and views for better test coverage.
    createQuery(label, label, createQueryRequest);
  }

  // Find the number of queries with the specified label
  private Integer findQueryByLabel(String label) {
    login(WIZARD_USER, WIZARD_PASSWORD);
    return newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get("/api/crud/listQueries").
      andReturn().jsonPath().getInt("queries.findAll {it.queryName == '" + label + "'}.size()");
  }

}