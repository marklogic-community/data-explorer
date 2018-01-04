package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameters;
import com.marklogic.dataexplorer.ClasspathAssets;
import com.marklogic.dataexplorer.ClasspathDeployer;

@Parameters(commandDescription = "Undeploy Data Explorer from MarkLogic")
public class UndeployCommand extends AbstractCommand {

	@Override
	protected void doExecute(ClasspathAssets assets) {
		logger.info("Undeploying Data-Explorer...");
		new ClasspathDeployer().processRequest(assets, false);
		logger.info("Undeployed Data-Explorer");
	}
}
