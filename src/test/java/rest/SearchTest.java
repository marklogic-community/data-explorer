package data_explorer.rest;

import data_explorer.AbstractTest;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.parsing.Parser;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.util.UUID;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

/**
 * SearchTest
 */

public class SearchTest extends AbstractTest {
  public String queryName;

  @Before
  public void setup() {
    // TODO: The endpoint really should be a post of JSON data. This will be addressed in issue #90
    // https://github.com/marklogic-community/data-explorer/issues/90
    String createQueryRequest = getResource("newQuery1.txt");

    // Create a random query/bookmark name
    UUID uuid = UUID.randomUUID();
    queryName = "test-query-" + uuid.toString();

    // Create a query in order to search the database
    createQuery(queryName, queryName, createQueryRequest);
  }

  @After
  public void destroy() {
    logout();
    deleteQuery("/default_ns:farmersMarket", queryName);
  }

  @Test
  public void searchWIthoutResults() {
    login(SEARCH_USER, SEARCH_PASSWORD);
    searchHasNoResults();

    // Wizard user should get the same results
    login(WIZARD_USER, WIZARD_PASSWORD);
    searchHasResults();
  }

  @Test
  public void searchWithResults() {
    login(SEARCH_USER, SEARCH_PASSWORD);
    searchHasResults();
    searchPages();

    // Wizard user should get the same results
    login(WIZARD_USER, WIZARD_PASSWORD);
    searchHasResults();
    searchPages();
  }

  @Test
  public void searchAgainstField() {
    login(SEARCH_USER, SEARCH_PASSWORD);
    searchFieldHasResults();
    searchFieldHasNoResults();

    // Wizard user should get the same results
    login(WIZARD_USER, WIZARD_PASSWORD);
    searchFieldHasResults();
    searchFieldHasNoResults();
  }

  private void searchFieldHasResults() {
    String results;
    // Get search results
    results = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get(getSearchCall("", "Inglewood")).
        andReturn().asString();
    // The server responds with text, so we can't use body()
    // 1 result
    assertTrue(results.contains("\"result-count\":\"1\""));
    // Inglewood is the value of city
    //assertTrue(results.contains("\"city\":\"Inglewood\""));
    System.out.println("Search Response: " + results);
  }

  private void searchFieldHasNoResults() {
    String results;
    // Get search results
    results = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get(getSearchCall("", "nocitybythatname")).
        andReturn().asString();
    // The server responds with text, so we can't use body()
    // No results
    assertTrue(results.contains("\"result-count\":\"0\""));
    System.out.println("Search Response: " + results);
  }

  private void searchHasResults() {
    String results;
    // Get search results
    results = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get(getSearchCall("flower")).
        andReturn().asString();
    // The server responds with text, so we can't use body()
    // 3 results
    assertTrue(results.contains("\"result-count\":\"3\""));
    // Flower City Park is part of the results.
    assertTrue(results.contains("Flower City Park"));
    System.out.println("Search Response: " + results);
  }

  private void searchHasNoResults() {
    String results;
    // Get search results
    results = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get(getSearchCall("therearenosearchresultsforthisstring")).
        andReturn().asString();
    // The server responds with text, so we can't use body()
    // 3 results
    assertTrue(results.contains("\"result-count\":\"0\""));
    System.out.println("Search Response: " + results);
  }

  private void searchPages() {
    String results;
    // Get search results and check for paging
    results = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get(getSearchCall("a")).
        andReturn().asString();
    // The server responds with text, so we can't use body()
    // 161 results
    assertTrue(results.contains("\"result-count\":\"161\""));
    // 17 pages
    assertTrue(results.contains("\"page-count\":\"17\""));
    // We're on the first page
    assertTrue(results.contains("\"current-page\":\"1\""));
    System.out.println("Search Pages Response: " + results);

    // Go to the next page and check the paging state
    results = newRequest().
            expect().
            statusCode(OK.getStatusCode()).
            when().
            get(getSearchCall("a", 2)).
            andReturn().asString();
    // The server responds with text, so we can't use body()
    // 161 results
    assertTrue(results.contains("\"result-count\":\"161\""));
    // 17 pages
    assertTrue(results.contains("\"page-count\":\"17\""));
    // We're on the second page
    assertTrue(results.contains("\"current-page\":\"2\""));
    System.out.println("Search Pages Response: " + results);
  }

  private String getSearchCall(String searchTerm) {
    return getSearchCall(searchTerm, 1);
  }

  private String getSearchCall(String searchTerm, Integer page) {
    return getSearchCall(searchTerm, page, "");
  }

  private String getSearchCall(String searchTerm, String field1) {
    return getSearchCall(searchTerm, 1, field1);
  }

  private String getSearchCall(String searchTerm, Integer page, String field1) {
    String request = getResource("search.txt");
    request = request.replace("{{QUERY_NAME}}", queryName);
    request = request.replace("{{SEARCH_TEXT}}", searchTerm);
    request = request.replace("{{PAGE_NUMBER}}", Integer.toString(page));
    request = request.replace("{{ID10}}", field1);
    return "/api/search" + request;
  }

}