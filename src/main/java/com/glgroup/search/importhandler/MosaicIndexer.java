package com.glgroup.search.importhandler;

import java.net.MalformedURLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;


import org.apache.solr.client.solrj.SolrServer;
import org.apache.solr.client.solrj.impl.LBHttpSolrServer;
import org.apache.solr.common.SolrInputDocument;

import com.mongodb.BasicDBObject;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.DBCursor;
import com.mongodb.DBObject;
import com.mongodb.Mongo;

import flexjson.JSONSerializer;
import org.apache.solr.common.params.SolrParams;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MosaicIndexer implements Runnable {
	
	private static final String DELIM = "|";
	private static final String RELATIONSHIPS_TOKENIZED = "relationships_tokenized";
	private static final String CURRENT_JOB_TOKENIZED = "current_job_tokenized";
	private static final String JOB_HISTORY_TOKENIZED = "jobHistory_tokenized";
	
	private SolrServer server;
	private String mongoHost;
	private int mongoPort;
	private String mongoDB;
	private String mongoCollection;
	private long maxdoc;
    private SolrParams defaults;
    private Logger log;
	
	public MosaicIndexer(String url, String mongoHost, int mongoPort, String mongoDB, String mongoCollection, long maxdoc, SolrParams defaults){
		 try {
			server = new LBHttpSolrServer(url);
		} catch (MalformedURLException e) {
			System.out.println("Malformed Solr URL:" + e);
			e.printStackTrace();
		}
		this.mongoHost = mongoHost;
		this.mongoPort = mongoPort;
		this.mongoDB = mongoDB;
		this.mongoCollection = mongoCollection;
		this.maxdoc = maxdoc;
		this.defaults = defaults;

		log = LoggerFactory.getLogger(MosaicIndexer.class);
	}
	
	public void run() {
		createIndexFromMongo(mongoHost, mongoPort, mongoDB, mongoCollection, maxdoc);
	}
	
	private void createIndexFromMongo(String mongoHost, int mongoPort, String mongoDB, String mongoCollection, long maxdoc){

		try {
			JSONSerializer serializer = new JSONSerializer();
			
			Mongo mongo = new Mongo(mongoHost, mongoPort);
			DB db = mongo.getDB(mongoDB);
			DBCollection collection = db.getCollection(mongoCollection);
			
			DBCursor cur = collection.find();

			// We'll add documents in batches, for performance
			long count = 0;
			HashSet<SolrInputDocument> docBatch = new HashSet<SolrInputDocument>();
			
	        while(cur.hasNext()) {
	        	DBObject doc = cur.next();
	        	Set<String>keys = doc.keySet();

	        	SolrInputDocument solrdoc = new SolrInputDocument();
	        	for (String key : keys) {
	        		if (key.equals("_id")) {
	        			continue;  // Skip ObjectId
	        		}
                    //TODO: remove job_history_tokenized
	        		// Process fields that are not simple values
	        		if (key.equals("relationships") || key.equals("jobHistory")) {
	        			String fieldName = JOB_HISTORY_TOKENIZED;
	        			if (key.equals("relationships")) {
	        				fieldName = RELATIONSHIPS_TOKENIZED;
	        			}
	        			// Store serialized form of the value, then parse it into parts
	        			String serialized = serializer.serialize(doc.get(key));
	        			solrdoc.addField(key, serialized);
	        			
	        			// "relationships" and "jobHistory" are both arrays of objects.
	        			// So, we iterate through the objects in the array, and
	        			// for each of them, iterate through their fields.
	        			// We create a tokenized string, separating each field with "|".
	        			DBObject subObject = (DBObject)doc.get(key);
	        			Set<String> subkeys = subObject.keySet();
	        			//System.out.println("subObject keyset/values: ");
	        			// Next array entry
	        			for (String k : subkeys) {
	        				//System.out.println("     " + k + "   " + subObject.get(k));
	        				DBObject o = (DBObject)subObject.get(k);
	        				Set<String> okeys = o.keySet();
	        				//System.out.println("          Contents of " + k);
	        				// Iterate through fields in the array entry.
	        				String tokenField = "";
	        				for (String ok : okeys) {
	        					//System.out.println("              " + ok + ": " + o.get(ok));
	        					if (tokenField.length() > 0) {
	        						tokenField = tokenField + "|";
	        					}
	        					tokenField = tokenField + ok + ":" + o.get(ok);
	        				}
	        				//System.out.println("fieldName: " + fieldName + "    value: " + tokenField);
	        				solrdoc.addField(fieldName, tokenField);
	        			}	        			
	        		} else {
	        			// "current_job" is not an array, but it does have subfields
	        			if (key.equals("current_job")) {
	        				String serialized = serializer.serialize(doc.get(key));
		        			solrdoc.addField(key, serialized);
		        			
	        				DBObject subObject = (DBObject)doc.get(key);
		        			Set<String> subkeys = subObject.keySet();
		        			//System.out.println("current_job keyset/values: ");
		        			String tokenField = "";
		        			for (String k : subkeys) {
		        				//System.out.println("     " + k + "   " + subObject.get(k));
		        				if (tokenField.length() > 0) {
	        						tokenField = tokenField + "|";
	        					}
	        					tokenField = tokenField + k + ":" + subObject.get(k);
		        			}
		        			//System.out.println("fieldName: " + CURRENT_JOB_TOKENIZED + "    value: " + tokenField);
		        			solrdoc.addField(CURRENT_JOB_TOKENIZED, tokenField);
	        			} 
	        			else 
	        			{ // vanilla field
	        				if (key.equals("relationship_count")) {
	        					  String relCountStr = "";
	        					  try {
	        						 relCountStr = serializer.serialize(doc.get(key));
	        					     Integer relCount = Integer.parseInt(relCountStr);
	        						 solrdoc.addField(key, relCount);
	        					  } catch (NumberFormatException nfex) {
	        						 System.out.println("Error getting Integer relationship count for : " + relCountStr + " "+ nfex);
	        						 nfex.printStackTrace();	        		    
	        					  } catch (Exception ex) {
	        						 System.out.println("Error getting relationship count:" + ex);
	        						 ex.printStackTrace();	        		    
	        				      }
	        				} 
	        				else 
	        				{
	        					if (defaults.get(key) != null) {
                                    solrdoc.addField(key, doc.get(key));
                                }
                                else {
                                    // When adding a new field to the mosaic-ngrams index,
                                    // you must also add it to the list of defaults
                                    // for the mosaicImport handler in solrconfig
                                    System.out.println("Skipping field not found in schema: " + key);
                                }
	        				}
	        			}
	        		}
	        	}
	        	   docBatch.add(solrdoc);
                   if ((count++ % maxdoc) == 0) {
                	   server.add(docBatch, 10000);
                	   docBatch = new HashSet<SolrInputDocument>();
                   }
                   
	        }
	           if (docBatch.size() > 0) {
	        	   server.add(docBatch);
	           }
	           server.commit();
	
		} catch (Exception e) {
			System.out.println("Error getting MongoDB:" + e);
			e.printStackTrace();
		}
	}
	
    // main method for use in debugging
	public static void main(String[] args) {	
		//MosaicIndexer mosaicIndexer = new MosaicIndexer("http://localhost:8983/solr/");
		
		//mosaicIndexer.createIndexFromMongo("192.168.56.101", 27017, "mosaic", "parties", 500);
	}
}
