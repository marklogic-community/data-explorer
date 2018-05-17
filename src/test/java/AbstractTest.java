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
import io.restassured.filter.cookie.CookieFilter;
import io.restassured.filter.session.SessionFilter;
import io.restassured.http.ContentType;
import io.restassured.parsing.Parser;
import io.restassured.response.Response;
import io.restassured.RestAssured;
import io.restassured.specification.RequestSpecification;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.IOException;
import java.util.Properties;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

public abstract class AbstractTest implements Constants {

  // Use cookie/session tracking for back to back rest tests
  CookieFilter cookieFilter = new CookieFilter();
  SessionFilter sessionFilter = new SessionFilter();

  String mlHost = "localhost";
  Integer mlRestPort = 7777;
  String mlUsername = "admin";
  String mlPassword = "admin";
  String demoDatabase = "Data-Explorer-content";

  public AbstractTest() {
    // Pull properties from gradle.properties to set the rest server and port
    Properties prop = new Properties();
    InputStream input = null;
    try {
      input = new FileInputStream("gradle.properties");
      prop.load(input);
      mlHost = prop.getProperty("mlHost");
      mlRestPort = Integer.valueOf(prop.getProperty("mlRestPort"));
      mlUsername = prop.getProperty("mlUsername");
      mlPassword = prop.getProperty("mlPassword");
      demoDatabase = prop.getProperty("demoDatabase");
    } catch (IOException ex) {
      ex.printStackTrace();
    }
    RestAssured.baseURI = "http://" + mlHost;
    RestAssured.port = mlRestPort;
    System.out.println("Initialized RestAssured at: " + RestAssured.baseURI + ":" + RestAssured.port);

    // Register a parser for text returns
    // TODO: The rest endpoints should be fixed to always return JSON
    RestAssured.registerParser("text/plain", Parser.TEXT);
  }

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

  protected String getResource(String file) {
    try {
      return Resources.toString(Resources.getResource(getClass(), file), Charsets.UTF_8);
    } catch (IOException e) {
      throw new RuntimeException("Could not find file: " + file, e);
    }
  }

  protected long getDocumentCountByCollection(String collection) {
    DigestAuthContext auth = new DigestAuthContext(mlUsername, mlPassword);
    DatabaseClient client = DatabaseClientFactory.newClient(mlHost, 8002, demoDatabase, auth);
    QueryManager queryMgr = client.newQueryManager();
    StructuredQueryBuilder qb = new StructuredQueryBuilder();
    StructuredQueryDefinition querydef = qb.collection(collection);
    SearchHandle results = queryMgr.search(querydef, new SearchHandle());
    return results.getTotalResults();
  }

}