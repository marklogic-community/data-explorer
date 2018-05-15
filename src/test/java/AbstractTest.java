package data_explorer;

import data_explorer.Constants;

import io.restassured.RestAssured;
import io.restassured.specification.RequestSpecification;
import java.io.InputStream;
import java.io.IOException;
import java.io.FileInputStream;
import java.util.Properties;
import org.junit.Before;

public abstract class AbstractTest implements Constants {

  @Before
  public void configure() {
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
  }

  protected RequestSpecification newRequest() {
    return RestAssured.
      given().
        header("Authorization", "Bearer loggedin");
  }

}