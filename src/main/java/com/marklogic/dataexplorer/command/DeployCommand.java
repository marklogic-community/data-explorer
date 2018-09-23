package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.marklogic.dataexplorer.ClasspathAssets;
import com.marklogic.dataexplorer.ClasspathDeployer;
import com.marklogic.mgmt.resource.security.PrivilegeManager;

@Parameters(commandDescription = "Deploy Data Explorer to MarkLogic")
public class DeployCommand extends AbstractCommand {

	@Parameter(names = "--mlRestPort", description = "Port that the Data Explorer should listen to after being deployed to MarkLogic")
	private Integer port = 7777;

	@Override
	protected void doExecute(ClasspathAssets assets) {
		logger.info("Deploying Data-Explorer...");

		ClasspathDeployer deployer = new ClasspathDeployer();
		configureDeployerToNotDeployMl9SpecificPrivileges(deployer);
		deployer.processRequest(assets, true);

		logger.info("Deployed Data-Explorer");
	}

	@Override
	protected void copyParametersToSystemProperties() {
		super.copyParametersToSystemProperties();
		if (port != null) {
			System.setProperty("mlRestPort", port.toString());
		}
	}

	protected void configureDeployerToNotDeployMl9SpecificPrivileges(ClasspathDeployer deployer) {
		deployer.setBeforeDeployCallback(context -> {
			PrivilegeManager mgr = new PrivilegeManager(context.getManageClient());
			if (!mgr.exists("admin-database", "kind", "execute")) {
				logger.info("admin-database privilege does not exist, so will not include it in data-explorer-ext-amp-role role");
				context.getAppConfig().getCustomTokens().put("%%adminDatabasePrivilege%%", "");
			}
			if (!mgr.exists("term-query", "kind", "execute")) {
				logger.info("term-query privilege does not exist, so will not include it in data-explorer-ext-amp-role role");
				context.getAppConfig().getCustomTokens().put("%%termQueryPrivilege%%", "");
			}
		});
	}
}
