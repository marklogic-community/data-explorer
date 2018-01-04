package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;
import com.marklogic.client.ext.helper.LoggingObject;
import com.marklogic.dataexplorer.ClasspathAssets;

public abstract class AbstractCommand extends LoggingObject implements Command {

	@Parameter(names = "--mlHost", description = "Host name of the MarkLogic server to deploy Data Explorer to")
	private String host;

	@Parameter(names = "--mlUsername", description = "MarkLogic user that has at least the manage-admin and rest-admin roles needed for deploying Data Explorer")
	private String username;

	@Parameter(names = "--mlPassword", description = "Password for the MarkLogic user defined by mlUsername")
	private String password;

	@Override
	public final void execute(ClasspathAssets assets) {
		copyParametersToSystemProperties();
		doExecute(assets);
	}

	protected abstract void doExecute(ClasspathAssets assets);

	protected void copyParametersToSystemProperties() {
		if (host != null) {
			System.setProperty("mlHost", host);
		}
		if (username != null) {
			System.setProperty("mlUsername", username);
		}
		if (password != null) {
			System.setProperty("mlPassword", password);
		}
	}
}
