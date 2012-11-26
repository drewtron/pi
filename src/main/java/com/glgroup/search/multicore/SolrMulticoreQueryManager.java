package com.glgroup.search.multicore;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.solr.client.solrj.SolrQuery;
import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.SolrServerException;
import org.apache.solr.client.solrj.impl.LBHttpSolrServer;
import org.apache.solr.client.solrj.response.QueryResponse;
import org.apache.solr.common.SolrDocument;
import org.apache.solr.common.SolrDocumentList;
import org.apache.solr.common.params.SolrParams;
import org.apache.solr.request.SolrQueryRequest;
import org.apache.solr.servlet.SolrRequestParsers;

import ucar.ma2.Section.Iterator;

import com.glgroup.search.util.Pair;
 

public class SolrMulticoreQueryManager {
	private int numCandidates=1000;
	private int numResults = 50;
	List<SolrServer>servers;
	List<Set<String>>validFields;
	SolrServer bioServer;
	Set<String>bioFields;
	
	public SolrMulticoreQueryManager(URL mainURL, List<URL>urls, int numCandidatesArg, int numResultsArg){
		this.numCandidates = numCandidatesArg;
		this.numResults = numResultsArg;
		try{
			bioServer = new LBHttpSolrServer(mainURL.getPath());
			bioFields = retrieveValidFields(mainURL);
			
			validFields = new ArrayList<Set<String>>();
			servers = new ArrayList<SolrServer>();
			for (URL u : urls){
				SolrServer server = new LBHttpSolrServer(u.getPath());
				servers.add(server);
				Set<String> fields = retrieveValidFields(u);
				validFields.add(fields);
			}
		}catch(Exception e){
			System.out.println("Malformed URL:" + e);
			e.printStackTrace();
		}
	}
	
	public SolrDocumentList PerformSearchRequireBio(SolrQueryRequest req, String commonField){
		final SolrDocumentList output = new SolrDocumentList();
		
		boolean hasFacets = containsFacetQuery(req);
		Set<Object>validIDs = getValidCMS(req, commonField);
		
		// populate cf map
		Map<Object, List<SolrDocument>> cfMap = new HashMap<Object, List<SolrDocument>>(); 
        populateCFMap(commonField, req, cfMap, hasFacets);
		
		//perform search on bio server
		Map<Object, SolrDocument> bioMap = new HashMap<Object, SolrDocument>();
		boolean matchedWithCfScores = populateBioMap(commonField, output, req, cfMap, bioMap, validIDs, hasFacets);
		
		if(matchedWithCfScores) {
			//for every cf in cfMap calculate top scores
			List<Pair<Double, Object>> cfscores = populateCfTopScoresMap(cfMap, bioMap);
			//return top n docs
			getTopNResults(output, commonField, cfMap, bioMap, cfscores);
		}

		return output;
	}
	
	
	SolrDocument getPerson(String idField, Object id){
		try{
			SolrQuery params = new SolrQuery();
			params.setQuery(idField + ":" + id);
			params.setIncludeScore(true);
			params.set("rows", 1);
			QueryResponse response = bioServer.query(params);
			SolrDocumentList docs = response.getResults();
			if (!docs.isEmpty()){
				return docs.get(0);
			}
		}catch (SolrServerException e) {
			System.out.println("Error finding record by id:" + e);
			e.printStackTrace();
		}
		return new SolrDocument();
	}
	
	/**
	 * @param commonField
	 * @param output
	 * @param cfMap
	 * @param bioMap
	 */
	boolean populateBioMap(String commonField, final SolrDocumentList output,
			SolrQueryRequest req, Map<Object, List<SolrDocument>> cfMap,
			Map<Object, SolrDocument> bioMap, Set<Object>validIDs, boolean containsFacets) {
		boolean matchedWithCfScores = true;
		try{
			SolrQuery query;
			if (containsFacets){
				//perform term query
				query = getTermQuery(bioFields, req);
			}else{
				//query normally
				query = getValidQuery(bioFields, req);
			}
			
			 
			QueryResponse response = bioServer.query(query);
			SolrDocumentList docs = response.getResults();
			if ((!docs.isEmpty()) && (cfMap.isEmpty())){
				matchedWithCfScores = false;
				for (SolrDocument doc : docs){
					if (output.size() > this.numResults){
						break;
					}
					Object id = doc.get(commonField);
					if ((!containsFacets) || (containsFacets && (validIDs.contains(id)))){
						output.add(doc);
					}
				}
			} else {
				//populate bioMap
				for (SolrDocument doc : docs){
					Object id = doc.get(commonField);
					
					if ((!containsFacets) || (containsFacets && (validIDs.contains(id)))){
						float score = ((Float)doc.get("score"))/docs.getMaxScore();
						doc.addField("normalizedScore", score);
						bioMap.put(id, doc);
					}
				}
			}
		}catch (SolrServerException e) {
			System.out.println("Error from solr bio server:" + e);
			e.printStackTrace();
		}
		return matchedWithCfScores;
	}

	/**
	 * @param commonField
	 * @param output
	 * @param cfMap
	 * @param bioMap
	 * @param cfscores
	 */
	void getTopNResults(SolrDocumentList output,  String commonField, 
			Map<Object, List<SolrDocument>> cfMap,
			Map<Object, SolrDocument> bioMap,
			List<Pair<Double, Object>> cfscores) {
		int count = 0;
		for (Pair<Double, Object> p : cfscores){
			if (count > this.numResults){
				break;
			}
			SolrDocument outputDoc;
			//add document;
			//how do we merge fields together?
			Object key = p.getValue();
			//add bio server document
			if (bioMap.containsKey(key)){
				outputDoc = bioMap.get(key);
			}else{
			//if it doens't exist search for it
				outputDoc = getPerson(commonField, key);
			}
			
			List<SolrDocument>docs = cfMap.get(key);
			for (SolrDocument d : docs){
				for (String fieldName : d.getFieldNames()){
					outputDoc.addField(fieldName, d.get(fieldName));
				}
			}
			output.add(outputDoc);
			count++;
		}
	}

	/**
	 * @param cfMap
	 * @param bioMap
	 * @return
	 */
	List<Pair<Double, Object>> populateCfTopScoresMap(
			Map<Object, List<SolrDocument>> cfMap,
			Map<Object, SolrDocument> bioMap) {
		List<Pair<Double, Object>>cfscores = new ArrayList<Pair<Double, Object>>();
		for (Map.Entry<Object, List<SolrDocument>> entry : cfMap.entrySet()){
			double aggScore = 0;
			int numVals = 0;
			for (SolrDocument d : entry.getValue()){
				aggScore+=(Float)d.get("normalizedScore");
				numVals++;
			}
			//check bio server for key add score if it exists
			if (bioMap.containsKey(entry.getKey())){
				aggScore+=(Float)bioMap.get(entry.getKey()).get("normalizedScore");
				numVals++;
			}
			
			if (aggScore > 0){
				//insert pair<avgAggScore, Key> into cfScores
				cfscores.add(new Pair<Double, Object>(aggScore/numVals, entry.getKey()));
			}
		}
		Collections.sort(cfscores);
		return cfscores;
	}

	/**
	 * @param commonField
	 * @return
	 */
	Map<Object, List<SolrDocument>> populateCFMap(String commonField,
			SolrQueryRequest req, Map<Object, List<SolrDocument>> cfMap, 
			boolean containsFacets) {
		
		//if we have facets it's the intersection of IDS across cores
		//populate the first facet core, only these IDS are then valid 
		//on subsequent faceted cores remove i
		boolean populatedIDs = false;
		Set<Object>validIDs = new HashSet<Object>();
		
		for (int i = 0; i < servers.size(); i++){
			SolrServer s = servers.get(i);
			Set<String>fields = validFields.get(i);
			SolrQuery query = getValidQuery(fields, req);
			
			
			try {
				boolean coreHasFacets = containsFacetQuery(query);
				Set<Object>coreIds = new HashSet<Object>();
				QueryResponse response = s.query(query);
				SolrDocumentList docs = response.getResults();
				
				//populate cfMap
				for (SolrDocument doc : docs){
					boolean addDoc = false;
					Object id = doc.get(commonField);
					
					if (containsFacets){
						//if the first facet core hasn't been populated add all ids
						//add all docs to cfMap
						if (!populatedIDs){
							addDoc = true;
							if (coreHasFacets){
								validIDs.add(id);
							}
						}else {
							if (validIDs.contains(id)){
								addDoc = true;
							}
						}
						coreIds.add(id);
					}else{
						addDoc = true;
					}
				
					if (addDoc){
						List<SolrDocument> resultDocs;
						if (cfMap.containsKey(id)){
							resultDocs = cfMap.get(id);
						}else{
							resultDocs = new ArrayList<SolrDocument>();
						}
						
						float score = ((Float)doc.get("score"))/docs.getMaxScore();
						doc.addField("normalizedScore", score);
						resultDocs.add(doc);
						
						cfMap.put(id, resultDocs);
					}
				}
				
				if (containsFacets){
					if ((!populatedIDs) && (validIDs.size() > 0)){
						populatedIDs = true;
					}
					if (coreHasFacets && populatedIDs){
						validIDs.retainAll(coreIds);
					}
				}
			} catch (SolrServerException e) {
				System.out.println("Error from solr server:" + e);
				e.printStackTrace();
			}
			
			if (containsFacets && populatedIDs){
				//remove non-valid IDS from cfMap
				List<Object>remove = new ArrayList<Object>();
				for (Object key : cfMap.keySet()){
					if (!validIDs.contains(key)){
						remove.add(key);
					}
				}
				for (Object key : remove){
					cfMap.remove(key);
				}
			}
		}
		return cfMap;
	}
	
	//null is returned for all cms valid (no facet query)
	protected Set<Object> getValidCMS(SolrQueryRequest req, String commonField){
		SolrQuery facetQuery = getFacetQuery(bioFields, req);
		if (facetQuery == null){return null;}
		facetQuery.set("rows", this.numCandidates*3);
		facetQuery.add("fl", commonField);
		Set<Object>cmids = new HashSet<Object>();
		
		try {
			QueryResponse response = bioServer.query(facetQuery);
			SolrDocumentList docs = response.getResults();
			
			//populate cfMap
			for (SolrDocument doc : docs){
				cmids.add(doc.get(commonField));
			}
		} catch (SolrServerException e) {
			System.out.println("Error querying server:" + e);
			e.printStackTrace();
		}
		return cmids;
	}
	
	//return null if there's no facets
	protected SolrQuery getFacetQuery(Set<String> validFields, SolrQueryRequest req){
		SolrParams inputParams = req.getParams();
	    SolrQuery query = new SolrQuery();
	    
		java.util.Iterator<String> it = inputParams.getParameterNamesIterator();
		boolean setFilter = false;
		while (it.hasNext()){
			String key = it.next();
			//facet fields, filters and term queries can have fields specified
			if (key.equals("f") || key.equals("fq")){
				List<String>temp = new ArrayList<String>();
				for (String term : inputParams.getParams(key)){
					if (term.length() == 0){continue;}
					//check to see if a field is specified
					if (term.contains(":")){
						String field = term.substring(0, term.indexOf(":"));
						if (validFields.contains(field)){
							temp.add(term);
						}
					}else{
					//if there's no field specified it's general and just copy it over
						temp.add(term);
					}
				}
				if (temp.size() > 0){
					query.add(key, temp.toArray(new String[temp.size()]));
					setFilter = true;
				}
			}else if (!key.endsWith("?q")){
				//add fields verbatim except term field
				query.add(key, inputParams.getParams(key));
			}
		}
		if (!setFilter){return null;}
		query.setIncludeScore(true);
		query.set("rows", this.numCandidates);
		return query;
	}
	
	//return null if there's no term query
	protected SolrQuery getTermQuery(Set<String> validFields, SolrQueryRequest req){
		SolrParams inputParams = req.getParams();
	    SolrQuery query = new SolrQuery();
	    
		java.util.Iterator<String> it = inputParams.getParameterNamesIterator();
		boolean setTerms = false;
		while (it.hasNext()){
			String key = it.next();
			//facet fields, filters and term queries can have fields specified
			if (key.endsWith("?q")){
				List<String>temp = new ArrayList<String>();
				for (String term : inputParams.getParams(key)){
					if (term.length() == 0){continue;}
					//check to see if a field is specified
					if (term.contains(":")){
						String field = term.substring(0, term.indexOf(":"));
						if (validFields.contains(field)){
							temp.add(term);
						}
					}else{
					//if there's no field specified it's general and just copy it over
						temp.add(term);
					}
				}
				if (temp.size() > 0){
					query.add(key, temp.toArray(new String[temp.size()]));
					setTerms = true;
				}
			}
		}
		if (!setTerms){return null;}
		query.setIncludeScore(true);
		query.set("rows", this.numCandidates);
		return query;
	}
	
	protected SolrQuery getValidQuery(Set<String> validFields, SolrQueryRequest req){
	    SolrParams inputParams = req.getParams();
	    SolrQuery query = new SolrQuery();
	    
		java.util.Iterator<String> it = inputParams.getParameterNamesIterator();
		while (it.hasNext()){
			String key = it.next();
			//facet fields, filters and term queries can have fields specified
			if (key.equals("f") || key.equals("fq") || key.endsWith("?q")){
				List<String>temp = new ArrayList<String>();
				for (String term : inputParams.getParams(key)){
					//check to see if a field is specified
					if (term.contains(":")){
						String field = term.substring(0, term.indexOf(":"));
						if (validFields.contains(field)){
							temp.add(term);
						}
					}else{
					//if there's no field specified it's general and just copy it over
						temp.add(term);
					}
				}
				if (temp.size() > 0){
					query.add(key, temp.toArray(new String[temp.size()]));
				}
			}else{
				//add fields verbatim
				query.add(key, inputParams.getParams(key));
			}
		}
		query.setIncludeScore(true);
		query.set("rows", this.numCandidates);
		return query;
	}
	
	protected boolean containsFacetQuery(SolrQuery query){
		java.util.Iterator<String> it = query.getParameterNamesIterator();
		while (it.hasNext()){
			String key = it.next();
			if (key.equals("fq") || key.equals("f")){
				return true;
			}
		}
		return false;
	}
	
	protected boolean containsFacetQuery(SolrQueryRequest query){
		java.util.Iterator<String> it = query.getParams().getParameterNamesIterator();
		while (it.hasNext()){
			String key = it.next();
			if (key.equals("fq") || key.equals("f")){
				return true;
			}
		}
		return false;
	}
	
	protected static Set<String> retrieveValidFields(URL url){
		Set<String>output = new HashSet<String>();
		try{
			String tempURL = url.toString();
			if (tempURL.endsWith("/")){
				tempURL+= "admin/file/?contentType=text/xml;charset=utf-8&file=schema.xml";
			}else{
				tempURL+= "/admin/file/?contentType=text/xml;charset=utf-8&file=schema.xml";
			}
	        URLConnection con = new URL(tempURL).openConnection();
            con.connect();
            BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
            String line;
            Pattern fieldPattern = Pattern.compile("<field name=\"", Pattern.CASE_INSENSITIVE);
            Matcher m;
            
            while ((line = reader.readLine())!=null){
            	line = line.trim();
            	m = fieldPattern.matcher(line);
            	if (m.find()){
            		String field = line.substring(m.end(), line.indexOf('\"', m.end()));
            		output.add(field);
            	}
            }
            reader.close();
		}catch(Exception e){
			System.out.println("Error getting schema:" + e);
			e.printStackTrace();
		}
		return output;
	}
	
	public static void main(String[] args) throws Exception {
		
		//retrieveValidFields(new URL("http://localhost:8983/solr"));
		
		//String query = "http://localhost:8983/solr/select?q=camera&facet=on&facet.field=manu&fq=price:[400 to 500]&fq=camera_type:SLR";
		String query = "http://localhost:8983/solr/select?q=biography%3Aslashdot+AND+name%3AJeff&fq=inStock:true&fq=color:red&facet=true&facet.field=color&facet.field=category";
		query = "http://10.115.100.115:8983/solr/browse?q=evans&f=Test&fq=Council%3A%22Real+Estate%22&fq=PracticeArea%3A%22Financial+Services%22&fq=State%3A%22California%22&fq=Country%3A%22United+States%22&fq=Continent%3A%22North+America%22&fq=IndustryHierarchy%3A%22brokerag%22&queryOpts=spatial";
		SolrParams solrParams = SolrRequestParsers.parseQueryString(query);
		java.util.Iterator<String> it = solrParams.getParameterNamesIterator();
		while (it.hasNext()){
			String key = it.next();
			//System.out.println(key + " : " + solrParams.get(key));
			/*
			if (key.startsWith("fq")){
				String[] p = solrParams.getParams(key);
				for (String s : p){
					System.out.println(s);
				}
			}
			*/
			System.out.print(key + " | ");
			String[] params = solrParams.getParams(key);
			for (String p:params){
				System.out.print(p + ", ");
			}
			System.out.println();
		}
		
		System.out.println();
		for (Object obj : solrParams.toNamedList()){
			System.out.println(obj);
		}
		
		
		String schemaPath = "admin/file/?contentType=text/xml;charset=utf-8&file=schema.xml";
	}
	
}
