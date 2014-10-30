.PHONY: mongo

default:

mongo:
	echo Mongo build starting
	$(MAKE) people leads
	$(MAKE) council_members
	$(MAKE) -j council_member_details lead_details
	echo Mongo build complete


council_members:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_details: council_members council_member_addresses council_member_flags council_member_rates council_member_recruiters council_member_jobs council_member_tags council_member_projects council_member_gtc_counts council_member_projects council_member_pqs council_member_knowledge council_member_practice_areas council_member_average_rates council_member_logins

council_member_addresses:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_flags:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_rates:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_average_rates:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_recruiters:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_jobs:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_tags:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_projects:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_gtc_counts:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_pqs:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_knowledge:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_practice_areas:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_logins:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

people:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

leads:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

lead_details: lead_jobs

lead_jobs:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

forwill:
	GLGLIVE="glgdb150.glgresearch.com" GLGLIVE_USER="GLGR_reader" GLGLIVE_PWD="G1Gr!@#reader" HOME=~/pi DATA_DIR=~/pi/data ~/git/wballard/solr_jetty_java_buildpack/bin/compile .
