SHELL := /bin/bash
APP_USER_NAME := mosaic_search
APP_USER_PWD := SR58lzSfWeD8c
APP_ROOT_DIR := /home/$(APP_USER_NAME)/solr
HOST := $(shell hostname)

QA_CHEF_SERVER = http://10.45.206.208
PROD_CHEF_SERVER = http://glgnychef01.glgroup.com
REPO_URL = http://github.glgroup.com/SearchDeliveryTeam/pi

# Default to 'master' branch; override by executing 'sudo -u <root-user> make BRANCH=<some-branch>'
BRANCH = master

# Default to configuring everything for the Dev environment
ENVIRONMENT = mosaicsearch
CHEF_SERVER = $(QA_CHEF_SERVER):4000
PEM_URL = $(QA_CHEF_SERVER)/validation.pem
GIT_CHEF_URL = $(REPO_URL)/raw/$(BRANCH)/chef
CHEF_CONF_FILE = /etc/chef/client.rb.sub
CHEF_CONF_URL = $(GIT_CHEF_URL)/client.rb.sub
RUNLIST_FILE = /etc/chef/runlist.json
RUNLIST_URL = $(GIT_CHEF_URL)/runlist.json

JDKREPO = http://github.glgroup.com/SearchDeliveryTeam/Installers.git
JDK_INSTALLER = jdk-6u30-linux-x64.bin
JAVA_ROOT = /home/$(APP_USER_NAME)/lib/java
JAVA_HOME = $(JAVA_ROOT)/jdk1.6.0_30
JDK_DOWNLOAD_DIR = /home/$(APP_USER_NAME)/Installers

#IP Segment 1
TEMP = $(shell bash -c "ifconfig eth0 | grep 'inet addr' | cut -d : -f2 | cut -d ' ' -f1 | cut -d . -f1" )
IPSEG1 := $(TEMP)
#IP Segment 2
TEMP = $(shell bash -c "ifconfig eth0 | grep 'inet addr' | cut -d : -f2 | cut -d ' ' -f1 | cut -d . -f2" )
IPSEG2 := $(TEMP)
#IP Segment 3
TEMP = $(shell bash -c "ifconfig eth0 | grep 'inet addr' | cut -d : -f2 | cut -d ' ' -f1 | cut -d . -f3" )
IPSEG3 := $(TEMP)

# Based on network configuration, we know what environment we are in
ifeq ($(IPSEG1),10)
	ifeq ($(IPSEG2),20)
		PEM_URL = $(PROD_CHEF_SERVER)/validation.pem
		CHEF_SERVER = $(PROD_CHEF_SERVER):4000
	endif
endif

default: base_install
	# ***************************************
	# CONFIGURE CHEF-CLIENT
	# ***************************************
	mkdir -p /home/$(APP_USER_NAME)/chef
	mkdir -p /etc/chef
	# Create log folder for Chef here, since it will try to use it before any recipes run and won't
	# create it if it's not there
	mkdir -p /home/$(APP_USER_NAME)/logs/chef
	touch /home/$(APP_USER_NAME)/logs/chef/chef-client.log
	# Fetch validation.pem from chef server
	cd /etc/chef; curl -O $(PEM_URL); curl -O $(CHEF_CONF_URL); curl -O $(RUNLIST_URL)
	sed  -e s@HOST@$(HOST)@ -e s@CHEF_SERVER@$(CHEF_SERVER)@ -e s@APP_USER_NAME@$(APP_USER_NAME)@ $(CHEF_CONF_FILE) > /etc/chef/client.rb
	#
	#
	#
	# ***************************************
	# START-UP CHEF-CLIENT
	# ***************************************
	chef-client -E $(ENVIRONMENT) -j $(RUNLIST_FILE)
	#
	# ***************************************
	# END OF SOLR MAKEFILE

dev_install: base_install
    git clone git@github.glgroup.com:CHEF/Cookbooks.git /home/$(APP_USER_NAME)/cookbooks

	# Create log folder for Chef here, since it will try to use it before any recipes run and won't
	# create it if it's not there
	mkdir -p /home/$(APP_USER_NAME)/logs/chef
	touch /home/$(APP_USER_NAME)/logs/chef/chef-client.log

	chef-solo -c ./chef/solo.rb -j ./chef/solo.json


base_install:
	# ***************************************
	# DEFINED MACROS
	# ***************************************
	echo $(APP_USER_NAME) #APP_USER_NAME
	echo $(APP_USER_PWD) #APP_USER_PWD
	echo $(BRANCH) #BRANCH NAME
	echo $(CHEF_SERVER)#CHEF_SERVER
	echo $(CHEF_CONF_URL) # CHEF CONF URL
	echo $(ENVIRONMENT) #ENVIRONMENT
	echo $(GIT_CHEF_URL) #GIT CHEF URL
	echo $(HOST) #HOST
	echo $(IPSEG1) #IP SEG 1
	echo $(IPSEG2) #IP SEG 2
	echo $(IPSEG3) #IP SEG 3
	echo $(JAVA_ROOT)	#JAVA_ROOT
	echo $(JAVA_HOME)	#JAVA_HOME
	echo $(PEM_URL)	#PEM
	echo $(RUNLIST_URL) #RUNLIST URL
	echo $(SHELL)	#SHELL
	#
	#

	# ***************************************
	# CREATE APP USER
	# ***************************************
	id $(APP_USER_NAME) 2>/dev/null ; [ $$? -eq 0 ] && echo "user exists" || useradd -m -s /bin/bash $(APP_USER_NAME)
	usermod -p $(APP_USER_PWD) $(APP_USER_NAME)
	usermod -G 112 $(APP_USER_NAME)
	apt-get -y clean
	apt-get -y update
	#
	#

	# ***************************************
	# CREATE APP ROOT DIR
	# ***************************************
	su -l $(APP_USER_NAME) -c "mkdir -p $(APP_ROOT_DIR)"
	#
	#

	# ***************************************
	# APT-GET PRE-REQUISITES
	# ***************************************
	apt-get -y install wget curl openjdk-6-jdk chkconfig
	#
	#

	# ***************************************
	# APT-GET DEPENDENCIES
	# ***************************************
	apt-get -y install ruby1.8 ruby1.8-dev ri1.8 libopenssl-ruby1.8 libyaml-ruby1.8 libzlib-ruby1.8 rdoc1.8 irb1.8 build-essential ssl-cert libmysql-java
	#
	#

	# ***************************************
	# INSTALL RUBYGEMS
	# ***************************************
	curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
	tar zxf rubygems-1.8.10.tgz
	ruby rubygems-1.8.10/setup.rb --no-format-executable
	rm -rf rubygems-1.8.10*
	#
	#

	# ***************************************
	# INSTALL CHEF
	# ***************************************
	gem install chef -v 0.10.10 --no-ri --no-rdoc
	#
	#

	# ***************************************
	# GIT CLONE JDKREPO
	# ***************************************
	su -l $(APP_USER_NAME) -c "mkdir -p $(JDK_DOWNLOAD_DIR)"
	su -l $(APP_USER_NAME) -c "git clone $(JDKREPO) $(JDK_DOWNLOAD_DIR)"
	#
	#

	# ***************************************
	# INSTALL SUN/ORACLE JDK
	# ***************************************
	if [ ! -d $(JAVA_ROOT) ]; then mkdir -p $(JAVA_ROOT); fi
	mv $(JDK_DOWNLOAD_DIR)/$(JDK_INSTALLER) $(JAVA_ROOT)/
	chmod 755 $(JAVA_ROOT)/$(JDK_INSTALLER)
	cd $(JAVA_ROOT)/; echo "CD to: "; pwd; ./$(JDK_INSTALLER) -noregister
	rm -rf $(JAVA_ROOT)/$(JDK_INSTALLER) 
	update-alternatives --install "/usr/bin/java" "java" "$(JAVA_HOME)/bin/java" 1
	update-alternatives --set java $(JAVA_HOME)/bin/java
	#
	#
	# ***************************************
	# INSTALL BUILDR 
	# **************************************
	env JAVA_HOME=$(JAVA_HOME)/ gem install buildr -v 1.4.6 --no-ri --no-rdoc
