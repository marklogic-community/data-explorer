package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.marklogic.appdeployer.AppConfig;
import com.marklogic.appdeployer.DefaultAppConfigFactory;
import com.marklogic.client.DatabaseClient;
import com.marklogic.dataexplorer.ClasspathAssets;

/**
 * This uses xdmp:collection-delete, which seems to run fine on the 8,675 farmers market document. DMSDK would be safer,
 * but then this would be limited to running on ML9.
 */
@Parameters(commandDescription = "Delete demo data loaded via loadDeleteData")
public class DeleteDemoDataCommand extends AbstractCommand {

	@Parameter(names = {"--database", "-d"}, description = "The database containing the demo data")
	private String database = "Data-Explorer-content";

	@Parameter(names = {"--collection", "-c"}, description = "Collection to delete which contains the demo data")
	private String collection = "DemoData";

	@Override
	protected void doExecute(ClasspathAssets assets) {
		AppConfig appConfig = new DefaultAppConfigFactory(assets.newPropertySource()).newAppConfig();
		DatabaseClient client = appConfig.newAppServicesDatabaseClient(database);
		if (logger.isInfoEnabled()) {
			logger.info("Deleting collection: " + collection);
		}
		try {
			String xquery = String.format("xdmp:collection-delete('%s')", collection);
			client.newServerEval().xquery(xquery).eval();
			if (logger.isInfoEnabled()) {
				logger.info("Deleted collection: " + collection);
			}
		} finally {
			client.release();
		}
	}
}
