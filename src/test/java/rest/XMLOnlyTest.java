package data_explorer.rest;

import data_explorer.AbstractTest;

import org.apache.commons.io.IOUtils;
import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

import static javax.ws.rs.core.Response.Status.OK;

/**
 * XMLOnlyTest
 */

public class XMLOnlyTest extends AbstractTest {

  private static String documentName = "1001879.xml";

  @Before
  public void before() {
    // Login
    login(SEARCH_USER, SEARCH_PASSWORD);
  }

  @Test
  public void myNamedTest() throws IOException {
    // Get the control document
    String controlDoc = getResource(documentName);

    // Retrieve the same document from the API
    InputStream testDoc = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
                    when().
                    get("/api/get-xml-doc/Data-Explorer-content/" + documentName).
                asInputStream();

    // Convert the response to a string
    String result = IOUtils.toString(testDoc, StandardCharsets.UTF_8);

    // The API results are the same as the control document
    assertEquals(result, controlDoc);
    System.out.println("Check XML Doc Response: " + result);
  }

}