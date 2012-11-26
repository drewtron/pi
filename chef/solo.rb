solr_root = "/home/glgsearch/solr"

data_bag_path solr_root + '/chef/data_bags'

file_cache_path solr_root
cookbook_path solr_root + '/chef/cookbooks'

#node_name 'qatrendrs'
#node_name 'qasolrmaster'
#node_name 'qasolrslave02'
#node_name 'qasolrslave01'
#node_name 'mosaic-search'
node_name 'solrslave01'