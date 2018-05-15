package data_explorer.rest;

import data_explorer.AbstractTest;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertTrue;

/**
 * Foo
 */

public class FooTest extends AbstractTest {

  @Before
  public void setup() {
    System.out.println("BEFORE!!!!");
    assertTrue(TEST_CONSTANT == 1);
  }

  @Test
  public void doSomethingTest() {
    System.out.println("I'm a Test! Look at me test!!!");
    String test = newRequest().
    when().
        get("/api/checkTemplates/").
      andReturn().asString();
    System.out.println(test);
  }
}