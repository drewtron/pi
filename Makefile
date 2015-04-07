#you will need the buildpack
#git clone https://github.com/wballard/solr_jetty_java_buildpack.git ~/git/wballard/
localrun: localbuildpack
	$(HOME)/solr-home/start_solr

localbuildpack:
	GLGLIVE="glgdb150.glgresearch.com" GLGLIVE_USER="GLGR_reader" GLGLIVE_PWD="G1Gr!@#reader" HOME=~/pi DATA_DIR=~/pi/data ~/git/wballard/solr_jetty_java_buildpack/bin/compile .
