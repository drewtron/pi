To add a core:
-- Add core to chef/solo.json (see root level README and chef/README for details)
-- Add new folder for the core under pi-solr/solr-home/cores. The folder have the same name that was used in solo.json
-- Copy the conf folder from another core to your new folder
-- Adjust the information in the new conf folder:
   -- Adjust stopwords, if needed (see below)
   -- Change schema.xml:
      -- Make schema name match the core name (at the top of the file)
      -- Change the field definitions to match those in your new core
   -- Other changes, as needed (possibly none)

	
Stop wording
	Each core maintains its own list of stopwords within its conf directory.  When spinning up
	new cores, just be careful when you (likely) copy into this new core's conf another core's
	stopwords file because it may or may not contain what you'd expect.  Since each core has its
	own unique data focus/source, stopwords could vary between cores significantly
