package utils;

import com.marklogic.client.DatabaseClient;
import com.marklogic.client.DatabaseClientFactory;
import com.marklogic.client.io.SearchHandle;
import com.marklogic.client.query.QueryManager;
import com.marklogic.client.query.StructuredQueryBuilder;
import com.marklogic.client.query.StructuredQueryDefinition;
import data_explorer.TestConfig;

public class DataTools {

  protected TestConfig testConfig;

  public DataTools(TestConfig testConfig) {
    this.testConfig = testConfig;
  }

  public Long getDocumentCountByCollection(String collection) {
    DatabaseClientFactory.DigestAuthContext auth = new DatabaseClientFactory.DigestAuthContext(this.testConfig.mlUsername, this.testConfig.mlPassword);
    DatabaseClient client = DatabaseClientFactory.newClient(this.testConfig.mlHost, 8002, this.testConfig.demoDatabase, auth);
    QueryManager queryMgr = client.newQueryManager();
    StructuredQueryBuilder qb = new StructuredQueryBuilder();
    StructuredQueryDefinition querydef = qb.collection(collection);
    SearchHandle results = queryMgr.search(querydef, new SearchHandle());
    return results.getTotalResults();
  }

}
