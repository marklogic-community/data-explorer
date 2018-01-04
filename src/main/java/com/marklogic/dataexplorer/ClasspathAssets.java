package com.marklogic.dataexplorer;

import com.marklogic.client.ext.helper.LoggingObject;
import com.marklogic.mgmt.util.PropertySource;
import com.marklogic.mgmt.util.SimplePropertySource;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.util.Properties;

public class ClasspathAssets extends LoggingObject {

	private String path;
	private String propertiesFilename;
	private boolean overwritePropertiesWithSystemProperties = true;

	public ClasspathAssets(String path, String propertiesFilename) {
		this.path = path;
		this.propertiesFilename = propertiesFilename;
	}

	public PropertySource newPropertySource() {
		Properties props = new Properties();
		String fullPath = path + "/" + propertiesFilename;

		try {
			if (logger.isDebugEnabled()) {
				logger.debug("Loading properties from classpath file: " + fullPath);
			}
			props.load(new ClassPathResource(fullPath).getInputStream());
		} catch (IOException ex) {
			throw new RuntimeException("Unable to read properties from classpath path: " + fullPath + "; cause: " + ex.getMessage(), ex);
		}

		if (overwritePropertiesWithSystemProperties) {
			Properties systemProps = System.getProperties();
			for (Object key : systemProps.keySet()) {
				String skey = key.toString();
				props.setProperty(skey, systemProps.getProperty(skey));
			}
		}

		return new SimplePropertySource(props);
	}

	public void setOverwritePropertiesWithSystemProperties(boolean overwritePropertiesWithSystemProperties) {
		this.overwritePropertiesWithSystemProperties = overwritePropertiesWithSystemProperties;
	}

	public String getPropertiesFilename() {
		return propertiesFilename;
	}

	public String getPath() {
		return path;
	}
}
