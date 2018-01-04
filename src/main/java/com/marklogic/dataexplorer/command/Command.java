package com.marklogic.dataexplorer.command;

import com.marklogic.dataexplorer.ClasspathAssets;

public interface Command {

	void execute(ClasspathAssets assets);
}
