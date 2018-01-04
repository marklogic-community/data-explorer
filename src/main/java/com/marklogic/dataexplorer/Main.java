package com.marklogic.dataexplorer;

import com.beust.jcommander.JCommander;
import com.marklogic.dataexplorer.command.*;

public class Main {

	/**
	 * Performs a deployment operation using modules and configuration files added to the data-explorer.jar via the
	 * Gradle "jar" block in build.gradle. Defaults to running "deploy". If a command-line arg is present, then that
	 * is interpreted as the operation. Choices are "deploy", "undeploy", and "properties" (which just shows all the
	 * properties; it's just for testing).
	 *
	 * @param args
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception {
		Options options = new Options();

		JCommander commander = JCommander
			.newBuilder()
			.addObject(options)
			.addCommand("deploy", new DeployCommand())
			.addCommand("undeploy", new UndeployCommand())
			.addCommand("loadDemoData", new LoadDemoDataCommand())
			.addCommand("deleteDemoData", new DeleteDemoDataCommand())
			.acceptUnknownOptions(true)
			.build();

		commander.setCaseSensitiveOptions(false);
		commander.setProgramName("java -jar data-explorer.jar");
		commander.parse(args);

		String parsedCommand = commander.getParsedCommand();
		if (options.isHelp() || parsedCommand == null) {
			commander.usage();
		} else {
			JCommander parsedCommander = commander.getCommands().get(parsedCommand);
			AbstractCommand command = (AbstractCommand) parsedCommander.getObjects().get(0);

			ClasspathAssets assets = new ClasspathAssets("/META-INF/com.marklogic.dataexplorer", "data-explorer.properties");
			command.execute(assets);
		}
	}

}
