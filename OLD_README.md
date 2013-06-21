Trouble Shooting
----------------
Search & Recommendations Team [Escalation Info](http://confluence.glgroup.com:8090/display/GLGDev/_Escalation+Info+-+Search "Contact telephone numbers and system usage and urgenc information")

Admin Commands:

```
$ service solr status
$ service solr start
$ service solr stop
```
  

Adding cores
------------
Cores used by Solr are defined in the solo.json file for the Chef solo case,
or  in the '[env]trendsetter' Chef environment for the chef-client case.

solrconfig.xml files for each core are generated from a template, solrconfig.xml.erb,
so make any changes you need in that template or in attributes used by that template.

The schema for each core is also generated from a template, schema.xml.erb. Cores are 
divided into groups of related cores (all the payment cores, all the publication cores, etc.).
Each group has a set of fields defined in a json file in the "schemas" data bag. The
deployment recipe knows which field definitions to use by looking at the schema-map.json
file, which maps a core name to the name of a json file representing the schema (e.g., field definitions).

If you change the field definitions for a core, you must change the json file
in the "schemas" data bag. You must also adjust the schema-map file, if you've changed which
schema a core uses. 

When you make changes to any of the files in the schemas data bag, you must upload
the data bag to the Chef server using "knife data bag from file schemas [json file]".

If you are adding a new core, you must also create a folder for it in [git-repo]/ts-solr/solr-home/cores,
and create/copy a conf directory in that folder.


Rebuilding indexes regularly
----------------------------
The deploy_solr.rb recipe configures cron for each core based on attributes in the environment if they
exist, otherwise defaults to running every day at midnight (i.e., min=0, hr=0, day=*, weekday=*, month=*)

Attributes for full reloads are in a separate section outside the core definitions. See below.

Configure cron for each core by creating attributes under the core name in the <env>trendsetter environment in
Chef Server or in the <git-repo>/chef/solo.json

The acceptable values are directly from the cron man page

           attribute     allowed values
           ---------     --------------
           cron_min      0-59
           cron_hour     0-23
           cron_day      1-31
           cron_month    1-12 (or names, see below)
           cron_weekday  0-7 (0 or 7 is Sun, or use names)

     Values may be
       - an asterisk (*), which always stands for ``first-to-last''
       - a range of two numbers separated with a hyphen
       - a list of a set of numbers (or ranges) separated by commas
       - a step value where one of the above can be followed by a forward slash and a number
         (e.g., "8-18/30" would be every 30 min between 8 AM and 6 PM)
       - a name can be used for the month and day of week by using the first three letters of the particular day or
         month (case does not matter).  Ranges or lists of names are not allowed.

The index reload scripts are generated from  two reload templates, one for full reloads and one for deltas. This makes the template 
and ruby code cleaner and simpler. Although import_type is no longer used in the generated scripts 
(since they are either full or delta, not conjoined) it still appears in the cron job command, since 
it makes it easier for the user to determine what the job did.

Each core has a cron job to re-index the core periodically. There are three
ways a core may be re-indexed, based on the import_type attribute:
   fullonly: This is the default value. Cores with this setting
             are all loaded by a single cron job running a single script
             that makes a backup of the old index and then completely
             rebuilds it. This cron job is run once a week. Cores with
             the fulldaily setting are also included in this cron job.
   fulldaily: Cores with this setting are also processed by a single
              cron job running a single script that completely
              rebuilds the index. This cron job is run once a day, except
              for the day on which the fullonly job runs. The fullonly 
              job also includes the fulldaily cores. This is done to
              avoid running two re-indexing jobs at once, which may
              interfere with each other by stopping/starting Solr.
   delta: Cores with this setting each have their own cron job which
          performs a delta update. Each core has its own schedule
          attributes.

The following scripts are generated from the templates:
-- reload-daily.sh, which handles any cores that get full reloads every day. 
Right now this is just mosaic-ngrams. The cores are processed in a loop that starts imports for each, 
after Solr is stopped/started to make backups. This eliminates a problem we had with multiple full 
reloads running at the same time and interfering with each other (stopping Solr while a different reload was running).
-- reload-full.sh, which handles cores that get weekly full reloads. This also handles cores 
that get daily full reloads. (The schedule for reload-daily.sh skips the day on which reload-full runs). 
These cores are also processed in a loop to avoid interference.
-- reload-delta-<corename>.sh, one for each core that does delta updates.
-- reload-full-<corename>.sh, which does a full reload when a core's schema changes. 
These scripts are not cron'ed; they get run by chef.

The cron attributes for full imports are not defined in the individual cores because they are 
shared by all cores that do full imports. Since all full imports use a single script/cron job, 
there's no need to have distinct values for each core. Example:

	 "solr":  {
		
		...
		
		 "fullimport" : {
		        "weekly"    : "Sun",
		        "daily"     : "Mon-Sat",
		        "cron_min"  : "0",
		        "cron_hour" : "2",
		        "day"       : "*",
		        "month"     : "*"
		    },
		    "cores": {
		    	"mosaic": {
		          "import_type": "fullonly"
		        },
		        "mosaic-ngrams": {
		          "import_type": "fulldaily"
		        },
		        "kpq": {
		          "cron_min": "0",
		          "cron_hour": "8-18/2",
		          "database": "glgsearch",
		          "import_type": "delta"
		        },
		        "upq": {
		          "cron_min": "30",
		          "cron_hour": "8-18/2",
		          "database": "glgsearch",
		          "import_type": "delta"
		        }
		    }
		}


********* DEPLOYING *********

Chef client
-----------
If you are deploying using chef-client, then first delete the target node and its corresponding
client from the Chef server. 

If you are deploying a slave, you must set the IP of the master 
in the Chef [env]trendsetter environment attributes under /solr/masterIP.

Next, copy the Makefile to the target VM and run the default target:
  $ scp -C Makefile [admin_user]@[host]:~/
  $ ssh -o 'StrictHostKeyChecking no' [admin_user]@[host] 'sudo make && exit'


Chef solo
---------
If you are deploying using Chef solo (this is the typical case for testing changes during development),
then define cores and other attributes in solo.json. See that file for example syntax. 

First, build using the solo buildfile:

$ buildr -f buildfile-solo.rb package

Next, copy the Makefile to your target VM and then run the base_install target:


  $ scp -C Makefile [admin_user]@[host]:~/
  $ ssh -o 'StrictHostKeyChecking no' [admin_user]@[host] 'sudo make base_install && exit'

After that, you must edit the solo.json file to set attributes for Solr masters and slaves:
-- solr:master -- Set to true if you are deploying a master, false for a slave.
-- solr:masterIP -- Set to the IP of the master Solr instance (not used by master instances)

In addition, make sure you have defined the repo and branch you want to deploy from:
-- "branch_name"         : "multicore",
-- "repo_name"           : "/SearchDeliveryTeam/TS-Solr.git",
For TS-Solr, the repo_name should probably always be TS-SOlr, as above. The branch 
should be your development branch. If the branch name is omitted, it defaults to "master".

Then, run the deployment script:

scripts/remote_deploy_solr.sh [admin_user]@[host]


Thirdparty cookbooks
--------------------
11/15/12 - solr cookbook is now also in the CHEF/Cookbooks repo (as are most of the GLG project cookbooks).

You have to copy the thirdparty cookbooks from git@github.glgroup.com:CHEF/Cookbooks.git 
to your local cookbook folder (except for the windows cookbook -- copying this book may cause 
deployment issues in the solo case -- if you see an error about a missing file win32/open3, you 
should delete the windows cookbook). To deploy Solr, you should only need the solr cookbook and these third-party
cookbooks: apt, chef-client, chef_handler, python.

Notes on runlist in solo.json
-----------------------------

The solr_doctor and logrotate recipes must come AFTER the deploy_solr, since they
depend on things in that recipe.
