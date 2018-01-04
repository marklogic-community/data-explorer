package com.marklogic.dataexplorer.command;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;
import com.marklogic.appdeployer.AppConfig;
import com.marklogic.appdeployer.DefaultAppConfigFactory;
import com.marklogic.client.DatabaseClient;
import com.marklogic.client.document.DocumentWriteOperation;
import com.marklogic.client.ext.batch.RestBatchWriter;
import com.marklogic.client.ext.util.DefaultDocumentPermissionsParser;
import com.marklogic.client.impl.DocumentWriteOperationImpl;
import com.marklogic.client.io.DocumentMetadataHandle;
import com.marklogic.client.io.StringHandle;
import com.marklogic.dataexplorer.ClasspathAssets;
import org.springframework.core.io.ClassPathResource;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Parameters(commandDescription = "Load demo data (8,675 'farmers markets' documents) into MarkLogic")
public class LoadDemoDataCommand extends AbstractCommand {

	@Parameter(names = {"--database", "-d"}, description = "The database to load the demo data into")
	private String database = "Data-Explorer-content";

	@Parameter(names = {"--collection", "-c"}, description = "Collection to load the demo data into")
	private String collection = "DemoData";

	@Parameter(names = {"--permissions", "-p"}, description = "Comma-separated list of role,capability,role,capability,etc")
	private String permissions = "data-explorer-data-role,read,data-explorer-data-role,update";

	// The number of documents to write to MarkLogic in one call
	private int batchSize = 100;

	@Override
	protected void doExecute(ClasspathAssets assets) {
		ZipInputStream zipInputStream = null;
		try {
			String path = assets.getPath() + "/farmers-markets.zip";
			if (logger.isInfoEnabled()) {
				logger.info(String.format("Loading demo data into database %s and collection %s", database, collection));
			}
			ClassPathResource resource = new ClassPathResource(path);
			zipInputStream = new ZipInputStream(resource.getInputStream());
			ZipEntry zipEntry = zipInputStream.getNextEntry();

			// Use RestBatchWriter from ml-javaclient-util to load documents in a non-blocking fashion
			AppConfig appConfig = new DefaultAppConfigFactory(assets.newPropertySource()).newAppConfig();
			DatabaseClient client = appConfig.newAppServicesDatabaseClient(database);
			RestBatchWriter batchWriter = new RestBatchWriter(client, true);

			List<DocumentWriteOperation> list = new ArrayList<>();
			int counter = 0; // just used for logging
			while (zipEntry != null) {
				if (!zipEntry.isDirectory() && zipEntry.getName().endsWith(".xml")) {
					DocumentWriteOperation doc = buildDocumentFromZipEntry(zipEntry, zipInputStream);
					list.add(doc);
					if (list.size() >= batchSize) {
						batchWriter.write(list);
						list = new ArrayList<>();
					}
					counter++;
				}
				zipEntry = zipInputStream.getNextEntry();
			}
			batchWriter.write(list);
			batchWriter.waitForCompletion();
			if (logger.isInfoEnabled()) {
				logger.info("Finished loading demo data, count of documents loaded: " + counter);
			}
		} catch (IOException ex) {
			throw new RuntimeException("Unable to load demo data from zip file, cause: " + ex.getMessage(), ex);
		} finally {
			close(zipInputStream);
		}
	}

	protected DocumentWriteOperation buildDocumentFromZipEntry(ZipEntry zipEntry, ZipInputStream zipInputStream) throws IOException {
		String xml = readZipEntry(zipInputStream);
		DocumentMetadataHandle metadata = new DocumentMetadataHandle();
		if (collection != null) {
			metadata.getCollections().addAll(collection);
		}
		if (permissions != null) {
			new DefaultDocumentPermissionsParser().parsePermissions(permissions, metadata.getPermissions());
		}
		return new DocumentWriteOperationImpl(DocumentWriteOperation.OperationType.DOCUMENT_WRITE,
			zipEntry.getName(), metadata, new StringHandle(xml));
	}

	protected String readZipEntry(ZipInputStream zipInputStream) throws IOException {
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		byte[] buf = new byte[4096];
		int len;
		while ((len = zipInputStream.read(buf)) > 0) {
			baos.write(buf, 0, len);
		}
		return new String(baos.toString());
	}

	private void close(ZipInputStream zipInputStream) {
		if (zipInputStream != null) {
			try {
				zipInputStream.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

	public void setBatchSize(int batchSize) {
		this.batchSize = batchSize;
	}
}
