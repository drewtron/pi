
default:

vega:
	$(MAKE) people
	$(MAKE) council_members
	$(MAKE) council_member_details

council_member_details: council_members council_member_addresses council_member_flags council_member_rates council_member_recruiters council_member_jobs council_member_tags council_member_payments council_member_projects council_member_projects council_member_pqs council_member_knowledge

council_members:
	./script/vega ./queries/$@.sql | akw -f ./transforms/$@ | ./script/mongo

council_member_addresses:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_flags:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_rates:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_recruiters:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_jobs:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_tags:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_payments:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_projects:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_pqs:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

council_member_knowledge:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo

people:
	./script/vega ./queries/$@.sql | awk -f ./transforms/$@ | ./script/mongo
