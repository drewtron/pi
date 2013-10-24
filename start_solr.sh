cd ts-solr/jetty-home
java -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=7666  -Xmx8096m -Dsolr.solr.home=../solr-home -Djava.util.logging.config.file=./etc/solr-logging.properties  -jar start.jar
cd ../../

