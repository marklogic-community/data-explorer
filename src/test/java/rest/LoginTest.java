package data_explorer.rest;

import data_explorer.AbstractTest;

import io.restassured.response.Response;
import java.lang.String;
import org.junit.Test;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.equalTo;

/**
 * LoginTest
 */

public class LoginTest extends AbstractTest {

  @Test
  public void authenticateWizardUser() {
    // Login (returns a 200 and the username)
    Response r = login(WIZARD_USER, WIZARD_PASSWORD);
    System.out.println("Login Response: " + r.asString());

    // /api/users/me returns correct username and role
    String me = newRequest().
            expect().
            statusCode(OK.getStatusCode()).
            body("user.name", equalTo(WIZARD_USER)).
            body("user.role", equalTo("wizard-user")).
            when().
            get("/api/users/me").
            andReturn().asString();
    System.out.println("ME Response: " + me);

    // Logout (verifies 200)
    r = logout();
  }

  @Test
  public void authenticateSearchUser() {
    // Login (returns a 200 and the username)
    Response r = login(SEARCH_USER, SEARCH_PASSWORD);
    System.out.println("Login Response: " + r.asString());

    // /api/users/me returns correct username and role
    String me = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
        body("user.name", equalTo(SEARCH_USER)).
        body("user.role", equalTo("search-user")).
      when().
        get("/api/users/me").
      andReturn().asString();
    System.out.println("ME Response: " + me);

    // Logout (verifies 200)
    r = logout();
  }

}