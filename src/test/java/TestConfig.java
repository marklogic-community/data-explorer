package data_explorer;

import com.marklogic.client.ext.DatabaseClientConfig;
import com.marklogic.client.ext.helper.DatabaseClientProvider;
import com.marklogic.client.ext.spring.SimpleDatabaseClientProvider;
import io.restassured.parsing.Parser;
import io.restassured.RestAssured;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;
import org.springframework.context.support.PropertySourcesPlaceholderConfigurer;

@Configuration
@PropertySource(value = {"file:gradle.properties"}, ignoreResourceNotFound = true)
public class TestConfig implements InitializingBean {

  @Value("${mlHost:localhost}")
  public String mlHost;

  @Value("${mlRestPort:7777}")
  public Integer mlRestPort;

  @Value("${mlUsername:admin}")
  public String mlUsername;

  @Value("${mlPassword:admin}")
  public String mlPassword;

  @Value("${demoDatabase:Data-Explorer-content}")
  public String demoDatabase;

  /**
   * Reads from the gradle.properties file. Has to be static to run first.
   *
   * @return PropertySourcesPlaceholderConfigurer
   */
  @Bean
  public static PropertySourcesPlaceholderConfigurer propertyConfigurer() {
    PropertySourcesPlaceholderConfigurer c = new PropertySourcesPlaceholderConfigurer();
    c.setIgnoreResourceNotFound(true);
    return c;
  }

  /**
   * Required to create a DatabaseClient instance
   *
   * @return DatabaseClientConfig
   */
  @Bean
  public DatabaseClientConfig databaseClientConfig() {
    DatabaseClientConfig config = new DatabaseClientConfig(mlHost, 8002, mlUsername, mlPassword);
    config.setDatabase(demoDatabase);
    return config;
  }

  /**
   * Required to setup a DatabaseClient instance
   *
   * @return DatabaseClientProvider
   */
  @Bean
  public DatabaseClientProvider databaseClientProvider() {
    return new SimpleDatabaseClientProvider(databaseClientConfig());
  }

  /**
   * Initialize RestAssured with the host/port and create a text parser for it
   */
  @Override
  public void afterPropertiesSet() {
    RestAssured.baseURI = "http://" + mlHost;
    RestAssured.port = mlRestPort;
    System.out.println("Initialized RestAssured at: " + RestAssured.baseURI + ":" + RestAssured.port);

    // Register a parser for text returns
    // TODO: The rest endpoints should be fixed to always return JSON
    RestAssured.registerParser("text/plain", Parser.TEXT);
  }
}