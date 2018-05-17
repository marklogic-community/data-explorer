package data_explorer.rest;

import data_explorer.AbstractTest;
import data_explorer.GradleTaskRunner;

import org.junit.Test;

import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;

/**
 * LoadDeleteDemoData
 */

public class LoadDeleteDemoData extends AbstractTest {

  @Test
  public void DeleteAndLoadDemoData() {
    GradleTaskRunner task = new GradleTaskRunner();

    // Demo data should already be loaded.
    long count = getDocumentCountByCollection("DemoData");
    assertThat(count, is(not(0)));

    // Execute DeleteDemoData and ensure a zero count.
    task.run("DeleteDemoData");
    count = getDocumentCountByCollection("DemoData");
    assertThat(count, is(0L));

    // Execute LoadDemoData and ensure not a zero count.
    task.run("LoadDemoData");
    count = getDocumentCountByCollection("DemoData");
    assertThat(count, is(not(0L)));
  }

}