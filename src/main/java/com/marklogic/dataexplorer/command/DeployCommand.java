package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.marklogic.dataexplorer.ClasspathAssets;
import com.marklogic.dataexplorer.ClasspathDeployer;

@Parameters(commandDescription = "Deploy Data Explorer to MarkLogic")
public class DeployCommand extends AbstractCommand {

	@Parameter(names = "--mlRestPort", description = "Port that the Data Explorer should listen to after being deployed to MarkLogic")
	private Integer port = 7777;

	@Override
	protected void doExecute(ClasspathAssets assets) {
		logger.info("Deploying Data-Explorer...");
		new ClasspathDeployer().processRequest(assets, true);
		logger.info("Deployed Data-Explorer");
	}

	@Override
	protected void copyParametersToSystemProperties() {
		super.copyParametersToSystemProperties();
		if (port != null) {
			System.setProperty("mlRestPort", port.toString());
		}
	}
}
