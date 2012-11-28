puts 'Welcome to chef solo!'

solr_root = "/home/glgsearch/solr"
cookbooks = '/home/glgsearch/cookbooks'

data_bag_path(cookbooks + '/pi/data_bags')
file_cache_path(solr_root)
cookbook_path(cookbooks)

#node_name 'qatrendrs'
#node_name 'qasolrmaster'
#node_name 'qasolrslave02'
#node_name 'qasolrslave01'
#node_name 'mosaic-search'
#node_name 'solrslave01'