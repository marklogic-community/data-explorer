package com.marklogic.dataexplorer;

import com.marklogic.appdeployer.AppConfig;
import com.marklogic.appdeployer.DefaultAppConfigFactory;
import com.marklogic.appdeployer.command.Command;
import com.marklogic.appdeployer.command.CommandContext;
import com.marklogic.appdeployer.command.CommandMapBuilder;
import com.marklogic.appdeployer.command.modules.LoadModulesCommand;
import com.marklogic.appdeployer.impl.SimpleAppDeployer;
import com.marklogic.client.ext.file.JarDocumentFileReader;
import com.marklogic.client.ext.helper.LoggingObject;
import com.marklogic.client.ext.modulesloader.impl.AssetFileLoader;
import com.marklogic.client.ext.modulesloader.impl.DefaultFileFilter;
import com.marklogic.client.ext.modulesloader.impl.DefaultModulesLoader;
import com.marklogic.mgmt.DefaultManageConfigFactory;
import com.marklogic.mgmt.ManageClient;
import com.marklogic.mgmt.ManageConfig;
import com.marklogic.mgmt.admin.AdminConfig;
import com.marklogic.mgmt.admin.AdminManager;
import com.marklogic.mgmt.admin.DefaultAdminConfigFactory;
import com.marklogic.mgmt.util.PropertySource;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.util.FileCopyUtils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * Not quite the best name - this class knows how to deploy/undeploy an application from modules and configuration
 * files accessible from the classpath. It's original intent is to retrieve those files from a jar on the classpath,
 * and specifically, the jar that this class is stored in.
 */
public class ClasspathDeployer extends LoggingObject {

	public void processRequest(ClasspathAssets assets, boolean isDeploy) {
		final String path = assets.getPath();

		PropertySource propertySource = assets.newPropertySource();

		AppConfig appConfig = buildAppConfig(path, propertySource);
		ManageClient manageClient = buildManageClient(propertySource);
		AdminManager adminManager = buildAdminManager(propertySource);
		CommandContext commandContext = new CommandContext(appConfig, manageClient, adminManager);

		File configDir = writeConfigFilesToDirectory(path);
		appConfig.getConfigDir().setBaseDir(configDir);

		List<Command> commands = buildCommandList(commandContext, isDeploy);
		SimpleAppDeployer appDeployer = new SimpleAppDeployer(manageClient, adminManager, commands.toArray(new Command[]{}));

		if (isDeploy) {
			logger.info("Deploying application...");
			appDeployer.deploy(appConfig);
		} else {
			logger.info("Undeploying application...");
			appDeployer.undeploy(appConfig);
		}
	}

	protected AppConfig buildAppConfig(String path, PropertySource propertySource) {
		AppConfig appConfig = new DefaultAppConfigFactory(propertySource).newAppConfig();
		appConfig.setModulePaths(Arrays.asList("classpath*:" + path + "/ml-modules"));
		appConfig.setModuleTimestampsPath(null);
		return appConfig;
	}

	protected ManageClient buildManageClient(PropertySource propertySource) {
		ManageConfig manageConfig = new DefaultManageConfigFactory(propertySource).newManageConfig();
		return new ManageClient(manageConfig);
	}

	protected AdminManager buildAdminManager(PropertySource propertySource) {
		AdminConfig adminConfig = new DefaultAdminConfigFactory(propertySource).newAdminConfig();
		return new AdminManager(adminConfig);
	}

	/**
	 * If isDeploy = true, then the instance of LoadModulesCommand (if found) will be modified to read files from the
	 * classpath instead of from the filesystem.
	 *
	 * @param commandContext
	 * @param isDeploy
	 * @return
	 */
	protected List<Command> buildCommandList(CommandContext commandContext, boolean isDeploy) {
		Map<String, List<Command>> commandMap = new CommandMapBuilder().buildCommandMap();
		List<Command> commands = new ArrayList<>();
		for (String key : commandMap.keySet()) {
			for (Command command : commandMap.get(key)) {
				if (command instanceof LoadModulesCommand && isDeploy) {
					command = modifyLoadModulesCommand((LoadModulesCommand) command, commandContext);
				}
				commands.add(command);
			}
		}
		return commands;
	}

	/**
	 * Performs some surgery on the command - modifies the underlying AssetFileLoader to use a JarDocumentFileReader for
	 * finding modules to load.
	 *
	 * @param command
	 * @param context
	 * @return
	 */
	protected LoadModulesCommand modifyLoadModulesCommand(LoadModulesCommand command, CommandContext context) {
		command.initializeDefaultModulesLoader(context);

		AssetFileLoader assetFileLoader = ((DefaultModulesLoader) command.getModulesLoader()).getAssetFileLoader();
		JarDocumentFileReader jarDocumentFileReader = new JarDocumentFileReader();
		jarDocumentFileReader.addFilenameFilter(new DefaultFileFilter());
		assetFileLoader.prepareAbstractDocumentFileReader(jarDocumentFileReader);
		assetFileLoader.setDocumentFileReader(jarDocumentFileReader);

		return command;
	}

	protected File writeConfigFilesToDirectory(String path) {
		File tempConfigDir = getTempDirectoryToWriteConfigFilesTo(path);

		PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
		final String fullPath = "classpath:" + path + "/ml-config";
		final String locationPattern = fullPath + "/**";

		Resource[] resources;
		try {
			if (logger.isDebugEnabled()) {
				logger.debug("Finding configuration files on classpath using pattern: " + locationPattern);
			}
			resources = resolver.getResources(locationPattern);
		} catch (IOException ex) {
			throw new RuntimeException("Unable to get resources using location pattern: " + locationPattern + "; cause: " + ex.getMessage(), ex);
		}

		for (Resource r : resources) {
			ClassPathResource cpr = (ClassPathResource) r;
			String resourcePath = cpr.getPath();
			if (logger.isDebugEnabled()) {
				logger.debug("Checking to see if classpath location should be written out as a config file: " + resourcePath);
			}

			/**
			 * A classpath resource will have a path of e.g.
			 * META-INF/com.marklogic.dataexplorer/ml-config/databases/modules-database.json . Everything up to and
			 * include ml-config should be removed so that mlConfigDir can be the base configuration directory.
			 */
			String pathToRemove = path.startsWith("/") ? path.substring(1) : path.substring(0);
			pathToRemove += "/ml-config";
			String configFilePath = resourcePath.replace(pathToRemove, "");

			if (configFilePath.endsWith(".json") || configFilePath.endsWith(".xml")) {
				File out = new File(tempConfigDir, configFilePath);
				if (logger.isDebugEnabled()) {
					logger.debug(String.format("Writing classpath resource %s to file %s", resourcePath, out.getAbsolutePath()));
				}
				out.getParentFile().mkdirs();

				try {
					FileOutputStream fos = new FileOutputStream(out);
					try {
						FileCopyUtils.copy(cpr.getInputStream(), fos);
					} finally {
						fos.close();
					}
				} catch (IOException ex) {
					throw new RuntimeException("Unable to write config file to path: " + out.getAbsolutePath() + "; cause: " + ex, ex);
				}
			}
		}

		if (logger.isInfoEnabled()) {
			logger.info("Wrote application configuration files to path: " + tempConfigDir.getAbsolutePath());
		}

		return tempConfigDir;
	}

	protected File getTempDirectoryToWriteConfigFilesTo(String path) {
		int pos = path.lastIndexOf("/");
		String directoryName = pos > -1 ? path.substring(pos + 1) : path;

		File tmpDir = new File(System.getProperty("java.io.tmpdir"));
		File mlConfigDir = new File(tmpDir, directoryName + "-" + System.currentTimeMillis());
		mlConfigDir.mkdirs();
		return mlConfigDir;
	}

}
