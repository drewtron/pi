#you will need the buildpack
#git clone https://github.com/wballard/solr_jetty_java_buildpack.git ~/git/wballard/
localrun: localbuildpack
	~/pi/start_solr

localbuildpack:
	HOME=~/pi DATA_DIR=~/pi/data ~/git/wballard/solr_jetty_java_buildpack/bin/compile .
