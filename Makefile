
default:

vega:
	$(MAKE) -j people leads
	$(MAKE) council_members
	$(MAKE) -j council_member_details lead_details


council_members:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo
	
council_member_details: council_members council_member_addresses council_member_flags council_member_rates council_member_recruiters council_member_jobs council_member_tags council_member_payments council_member_projects council_member_projects council_member_pqs council_member_knowledge

council_member_addresses:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_flags:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_rates:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_recruiters:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_jobs:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_tags:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_payments:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_projects:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_pqs:
	./script/vega ./queries/$@.sql | gawk -f ./transforms/$@ | ./script/mongo

council_member_knowledge:
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
