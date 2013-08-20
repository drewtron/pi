require "nokogiri"

VERSION_NUMBER = "1.0.0"
GROUP = "Search & Recommendations"
# TODO: Need to automate resolution of (c) date to be 2012 - currentyear()
COPYRIGHT = "(c) 2012 - Gerson Lehrman Group"

desc "Get dependencies for the Mongo importer and update Solr config"

SOLR_HOME = "ts-solr/solr-home/"

define "pi" do

  project.version = VERSION_NUMBER
  project.group = GROUP
  manifest["Implementation-Vendor"] = COPYRIGHT

  task :config_env, :mongo_url, :mongo_password, :is_master, :master_ip, :dw_host, :dw_pwd do |task, args|

    puts "Config args: #{args.inspect}"

    update_config_files "#{SOLR_HOME}cores/*/conf/data-config.xml" do |doc, file_path|
      data_source = doc.xpath('//dataSource').first
      if data_source
        case data_source['type']
          when "MongoDataSource"
            data_source["host"] = args[:mongo_url]
            data_source["username"] = 'mosaicAdmin'
            data_source["password"] = args[:mongo_password]
          when "JdbcDataSource"
            data_source["url"] = "jdbc:mysql://#{args[:dw_host]}/ark"
            data_source["password"] = args[:dw_pwd]
          else
            raise "Unknown data source type #{data_source['type']}"
        end
      else
        raise "Could not find the dataSource section in #{file_path}"
      end
    end

    update_config_files "#{SOLR_HOME}cores/*/conf/solrconfig.xml" do |doc, file_path|
      core = /\/cores\/((\w|-)+)\//.match(file_path)[1]

      replication_frag = get_replication_fragment(args, core)

      config = doc.xpath('/config').first
      replication_handlers = doc.xpath("/config/*[@class='solr.ReplicationHandler' and @name='/replication']")

      replication_handlers.each {|h| h.remove}

      if config && replication_frag
        config.add_child(replication_frag)
      else
        raise "Could not find the config section in #{file_path}. Frag #{replication_frag}"
      end
    end

  end

  def update_config_files(file_pattern, &block)
    puts "Updating "
    Dir.glob file_pattern do |file_path|

      puts "Updating configuration in #{file_path}"
      doc = nil
      read_file = File.open(file_path)

      begin
        doc = Nokogiri::XML read_file
        block.call(doc, file_path)
      ensure
        read_file.close()
      end

      File.open(file_path, 'w+') do |f|
        f.write doc.to_xml
      end
    end
  end

  def get_replication_fragment(args, core)
    is_master = args[:is_master] == "true"
    master_ip = args[:master_ip]

    if is_master
      puts "Configuring node as master"
      Nokogiri::XML::DocumentFragment.parse <<-EOHTML
      <requestHandler name="/replication" class="solr.ReplicationHandler" >
        <lst name="master">
            <str name="replicateAfter">optimize</str>
            <str name="confFiles">schema.xml</str>
        </lst>
      </requestHandler>
      EOHTML
    else
      puts "Configuring node as slave"
      Nokogiri::XML::DocumentFragment.parse <<-EOHTML
      <requestHandler name="/replication" class="solr.ReplicationHandler" >
        <lst name="slave">
            <str name="masterUrl">http://#{master_ip}:8080/solr/#{core}/replication</str>
            <!--Interval in which the slave should poll master .Format is HH:mm:ss -->
            <str name="pollInterval">00:02:04</str>
        </lst>
      </requestHandler>
      EOHTML
    end
  end
end
