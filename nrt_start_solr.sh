cd ts-solr/jetty-home
java -Xmx8096m -Dsolr.solr.home=../solr-home -Dpeople.solr.data.dir=../solr-home/cores/people/data/nrt-data -Djetty.port=8081 -jar start.jar
cd ../../