package data_explorer.rest;

import data_explorer.AbstractTest;

import java.lang.String;
import java.util.UUID;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static javax.ws.rs.core.Response.Status.OK;
import static org.hamcrest.Matchers.equalTo;

/**
 * BookmarkTest
 */

public class BookmarkTest extends AbstractTest {

  public String label;

  @Before
  public void setup() {
    // TODO: The endpoint really should be a post of JSON data. This will be addressed in issue #90
    // https://github.com/marklogic-community/data-explorer/issues/90
    String createQueryRequest = getResource("newQuery1.txt");

    // Create a random query/bookmark name
    UUID uuid = UUID.randomUUID();
    label = "Test Query Bookmark-" + uuid.toString();

    // Create a bookmark to return
    createQuery(label, label, createQueryRequest);
  }

  @After
  public void destroy() {
    logout();
  }

  @Test
  public void BookmarkTest() {
    // Get our bookmark as a search user
    findBookmarkByLabel(SEARCH_USER, SEARCH_PASSWORD);

    // Get our bookmark as a wizard user
    findBookmarkByLabel(WIZARD_USER, WIZARD_PASSWORD);

  }

  // Test that our bookmark is returned in the listBookmarks call
  private void findBookmarkByLabel(String user, String password) {
    // Login with the supplied user
    login(user, password);

    // Get the bookmark list
    String bookmarkList = newRequest().
      expect().
        statusCode(OK.getStatusCode()).
        // A bookmark with our unique label is returned
        body("bookmarks.findAll {it.bookmarkLabel == '" + label + "'}.size()", equalTo(1)).
      when().
        get("/api/listBookmarks").
      andReturn().asString();
    System.out.println("Find Bookmark Resposne: " + bookmarkList);
  }

}