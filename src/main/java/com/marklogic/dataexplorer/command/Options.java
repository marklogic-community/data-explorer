package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;

/**
 * General options that must be specified before a command, or in the absence of a command.
 */
public class Options {

	@Parameter(names = {"--help", "-h"}, description = "Prints usage information", help = true)
	private boolean help;

	public boolean isHelp() {
		return help;
	}

	public void setHelp(boolean help) {
		this.help = help;
	}
}
