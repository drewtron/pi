This directory contains files required to run Jetty as the web server hosting Solr

From this (jetty-home) directory, the one that contains start.jar. 

1 - Edit the ../solr-home/solr.xml to point to where you've installed the 
	solr cores directory.

2 - Start solr by executing the following command
	> java -Dsolr.solr.home="../solr-home/" -jar start.jar

	start.jar starts the Jetty web server and by convention assumes that it's config file is located
	at ./etc/jetty.xml.  However, if supplied on the command line the config can be located anywhere
	e.g.,
	> java -Dsolr.solr.home="../solr-home/" -jar start.jar ./foo/bar.xml

3 - When Solr is started connect to 
	http://localhost:8983/solr/

To import data from the GLG_SEARCH database for councilmembers, connect to
	http://localhost:8983/solr/councilmembers/dataimport?command=full-import

To import data from the evernote folder, run the evernote-krawler.py in repo src/python directory.
The directions are in that folder


See also README.txt in the solr subdirectory, and check
http://wiki.apache.org/solr/DataImportHandler for detailed
usage guide and tutorial.
