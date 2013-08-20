cd ts-solr/jetty-home
java -Xmx8096m -Dsolr.solr.home=../solr-home -Djava.util.logging.config.file=./etc/solr-logging.properties  -jar start.jar
cd ../../

