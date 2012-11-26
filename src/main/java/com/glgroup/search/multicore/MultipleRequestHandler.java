package com.glgroup.search.multicore;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.util.NamedList;
import org.apache.solr.handler.RequestHandlerBase;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.request.SolrRequestHandler;
import org.apache.solr.response.SolrQueryResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MultipleRequestHandler extends RequestHandlerBase implements SolrRequestHandler {

	private static final Logger LOG = LoggerFactory.getLogger(MultipleRequestHandler.class);
	  
	List<URL> urls = new ArrayList<URL>();
	protected String mainUrl;
	protected String commonField;
	
	protected static final String MAIN_URL_ARG = "main.url";
	
	protected static final String CORE_ARG = "core";
	protected static final String URL_ARG = "url";
	
	protected static final String NUM_CANDIDATES_ARG = "num.candidates";
	protected static final String NUM_RESULTS_ARG = "num.results";

    protected static final String COMMON_FIELD = "common.field";

	private int numCandidates;
	private int numResults;
	
	@Override
	public void init(NamedList args) {
		super.init(args);
		try {
			// e.g. "http://10.115.100.115:8983/solr/cms/"
		    this.mainUrl = (String) defaults.get(MAIN_URL_ARG);
		    this.commonField = (String) defaults.get(COMMON_FIELD);

			String[] urlArr = (String[]) defaults.getFieldParams(CORE_ARG, URL_ARG);
			for (String url : urlArr) {
			    LOG.info("ADDING ++++++++++++++++++++++++++++++++++++++++++++++++: " + url.toString());
				urls.add(new URL(url));				
			}
		    LOG.info(urls.toString());
			numCandidates = Integer.valueOf(defaults.get(NUM_CANDIDATES_ARG).toString());
			numResults = Integer.valueOf(defaults.get(NUM_RESULTS_ARG).toString());

		} catch (NumberFormatException nfe) {
			numCandidates = 1000;
			numResults = 50;
			LOG.error("Exception thrown init() " + nfe);
		} catch (Exception e) {
			numCandidates = 1000;
			numResults = 50;
			LOG.error("Exception thrown init() " + e);
		}
	}

	@Override
	public void handleRequestBody(SolrQueryRequest req, SolrQueryResponse rsp) 
	{
		SolrDocumentList resultList = new SolrDocumentList();
		rsp.setHttpCaching(false);

		SolrMulticoreQueryManager mrh;
		try {
			mrh = new SolrMulticoreQueryManager(new URL(
					this.mainUrl), urls, this.numCandidates, this.numResults);
			resultList = mrh.PerformSearchRequireBio(req, this.commonField);
		} catch (MalformedURLException e) {
			LOG.error("Exception thrown handleRequest() " + e);
		}
		rsp.add("response", resultList);
	}

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
}
