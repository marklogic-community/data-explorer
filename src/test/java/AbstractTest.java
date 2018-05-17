package data_explorer;

import data_explorer.Constants;

import com.google.common.base.Charsets;
import com.google.common.io.Resources;
import com.marklogic.client.DatabaseClient;
import com.marklogic.client.DatabaseClientFactory;
import com.marklogic.client.DatabaseClientFactory.DigestAuthContext;
import com.marklogic.client.io.SearchHandle;
import com.marklogic.client.query.QueryManager;
import com.marklogic.client.query.StructuredQueryDefinition;
import com.marklogic.client.query.StructuredQueryBuilder;
import com.marklogic.junit.spring.AbstractSpringTest;
import io.restassured.filter.cookie.CookieFilter;
import io.restassured.filter.session.SessionFilter;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.RestAssured;
import io.restassured.specification.RequestSpecification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;

import java.io.IOException;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

@ContextConfiguration(classes = {TestConfig.class})
public abstract class AbstractTest extends AbstractSpringTest implements Constants {

  // Use cookie/session tracking for back to back rest tests
  CookieFilter cookieFilter = new CookieFilter();
  SessionFilter sessionFilter = new SessionFilter();

  @Autowired
  protected TestConfig testConfig;

  // Preload all requests with cookie/session data
  protected RequestSpecification newRequest() {
    return RestAssured.
      given().
        filter(cookieFilter).
        filter(sessionFilter);
  }

  // User login
  protected Response login(String user, String password) {
    // Make the login request and validate it.
    return newRequest().
      given().
        filter(sessionFilter).
        param("userid", user).
        param("password", password).
      expect().
        statusCode(OK.getStatusCode()).
        contentType(ContentType.TEXT).
        body(containsString(user)).
      when().
        post("/auth").
      andReturn();
  }

  // User logout
  protected Response logout() {
    // Logout and verify 200
    return newRequest().
      given().
        filter(sessionFilter).
      expect().
        statusCode(OK.getStatusCode()).
      when().
        post("/deauth").
      andReturn();
  }

  // Create a query with the supplied body
  protected void createQuery(String name, String bookmark, String queryBody) {
    // Login as wizard-user
    login(WIZARD_USER, WIZARD_PASSWORD);

    String queryRequestBody = "bookmarkLabel=" + bookmark + "&queryName=" + name  + queryBody;

    // Create the query/bookmark
    String query = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
        body("status", equalTo("saved")).
      when().
        get("/api/wizard/create?" + queryRequestBody).
      andReturn().asString();
    System.out.println("Create Query Response: " + query);

    // Logout once the query is created
    logout();
  }

  // Remove the query specified by docType, and name
  protected void deleteQuery(String docType, String name) {
    // Login as wizard-user
    login(WIZARD_USER, WIZARD_PASSWORD);

    String queryRequestBody = "docType=" + docType + "&queryName=" + name;

    // Create the query/bookmark
    String query = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
      when().
        get("/api/crud/removeQuery?" + queryRequestBody).
      andReturn().asString();
    System.out.println("Remove Query Response: " + query);

    // Logout once the query is created
    logout();
  }

  protected String getResource(String file) {
    try {
      return Resources.toString(Resources.getResource(getClass(), file), Charsets.UTF_8);
    } catch (IOException e) {
      throw new RuntimeException("Could not find file: " + file, e);
    }
  }

  protected long getDocumentCountByCollection(String collection) {
    DigestAuthContext auth = new DigestAuthContext(testConfig.mlUsername, testConfig.mlPassword);
    DatabaseClient client = DatabaseClientFactory.newClient(testConfig.mlHost, 8002, testConfig.demoDatabase, auth);
    QueryManager queryMgr = client.newQueryManager();
    StructuredQueryBuilder qb = new StructuredQueryBuilder();
    StructuredQueryDefinition querydef = qb.collection(collection);
    SearchHandle results = queryMgr.search(querydef, new SearchHandle());
    return results.getTotalResults();
  }

}