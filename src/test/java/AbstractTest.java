package data_explorer;

import data_explorer.Constants;

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
import org.junit.BeforeClass;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.containsString;

public abstract class AbstractTest implements Constants {

  // Use cookie/session tracking for back to back rest tests
  CookieFilter cookieFilter = new CookieFilter();
  SessionFilter sessionFilter = new SessionFilter();

  @BeforeClass
  public static void configure() {
    // Pull properties from gradle.properties to set the rest server and port
    Properties prop = new Properties();
    InputStream input = null;
    String mlHost = "localhost";
    Integer mlRestPort = 7777;
    try {
      input = new FileInputStream("gradle.properties");
      prop.load(input);
      mlHost = prop.getProperty("mlHost");
      mlRestPort = Integer.valueOf(prop.getProperty("mlRestPort"));
    } catch (IOException ex) {
      ex.printStackTrace();
    }
    RestAssured.baseURI = "http://" + mlHost;
    RestAssured.port = mlRestPort;
    System.out.println("Initialized RestAssured at: " + RestAssured.baseURI + ":" + RestAssured.port);

    // Register a parser for text returns
    // TODO: The rest endpoints should be fixed to always return JSON
    //RestAssured.registerParser("text/plain", Parser.TEXT);
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

}