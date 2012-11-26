#!/bin/bash

host="${1:?"remote_deploy_solr.sh expects user@hostname "}"

echo "Remove any previous Solr tar"
rm ../Solr.tar
echo "tar Solr dir"
tar -cj -f "../Solr.tar" --exclude .git .
echo "Deploy Solr to Remote Host"
scp -C ../Solr.tar $host:~/
ssh -t -o 'StrictHostKeyChecking no' $host 'sudo rm -rf /home/glgsearch/solr; \
    sudo mkdir -p /home/glgsearch/solr; \
    cd /home/glgsearch/solr; \
    sudo tar -xj -f ~/Solr.tar; \
    sudo chown -R glgsearch:glgsearch /home/glgsearch/solr; \
    sudo cp /home/glgsearch/solr/target/pi-solr.tgz /home/glgsearch/solr/pi-solr; \
    sudo rm -R /home/glgsearch/solr/pi-solr/solr-home; \
    cd /home/glgsearch/solr/pi-solr; \
    sudo tar -xzf /home/glgsearch/solr/pi-solr/pi-solr.tgz; \
    cd /home/glgsearch/solr/chef; \
    sudo chef-solo -c /home/glgsearch/solr/chef/solo.rb -l debug -j /home/glgsearch/solr/chef/solo.json && exit'
