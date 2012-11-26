package com.glgroup.search.importhandler;

import org.apache.solr.handler.RequestHandlerBase;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.request.SolrRequestHandler;
import org.apache.solr.response.SolrQueryResponse;

public class MosaicImportHandler extends RequestHandlerBase implements
		SolrRequestHandler {

// Arguments in solrconfig.xml
private static final String SOLR_SERVER = "solr.master.url";
private static final String MONGO_URL = "mongo.url";
private static final String MONGO_PORT = "mongo.port";
private static final String MONGO_DB = "mongo.db";
private static final String MONGO_COLLECTION = "mongo.columnstore";
private static final String MONGO_MAXDOC = "mongo.maxdoc";

	@Override
	public String getDescription() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String getSource() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String getVersion() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void handleRequestBody(SolrQueryRequest arg0, SolrQueryResponse arg1)
			throws Exception {
				
	//	MosaicIndexer mosaicIndexer = new MosaicIndexer("http://10.115.100.240:8983/solr/mosaic");
		
	//	mosaicIndexer.createIndexFromMongo("10.45.206.224", 27017, "mosaic", "parties");
	
	MosaicIndexer mosaicIndexer = new MosaicIndexer(defaults.get(SOLR_SERVER),
	                                                defaults.get(MONGO_URL), 
													Integer.valueOf(defaults.get(MONGO_PORT)), 
													defaults.get(MONGO_DB),
													defaults.get(MONGO_COLLECTION),
													Long.valueOf(defaults.get(MONGO_MAXDOC)),
                                                    defaults);

    (new Thread(mosaicIndexer)).start();

	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub

	}

}
