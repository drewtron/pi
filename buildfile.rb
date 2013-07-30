require "nokogiri"

VERSION_NUMBER = "1.0.0"
GROUP = "Search & Recommendations"
# TODO: Need to automate resolution of (c) date to be 2012 - currentyear()
COPYRIGHT = "(c) 2012 - Gerson Lehrman Group"

# Specify Maven 2.0 remote repositories here, like this:
repositories.remote << "http://repo1.maven.org/maven2" << "http://www.ibiblio.org/maven2" << "http://maven.restlet.org"

def solr_dependency(name)
  transitive(name + SOLR_VERSION).reject do |dep|
    dep.id == 'jmxtools' || dep.id == 'jmxri' || dep.group == 'javax.jms'
  end
end

# DEPENDENCIES
JTDS = 'net.sourceforge.jtds:jtds:jar:1.2.4'
BSON4JACKSON = 'de.undercouch:bson4jackson:jar:1.3.0'
FLEXJSON = transitive('net.sf.flexjson:flexjson:jar:2.1')
MONGO = transitive('org.mongodb:mongo-java-driver:jar:2.8.0')
MYSQL = transitive('mysql:mysql-connector-java:jar:5.1.20')
XALAN = transitive('xalan:serializer:jar:2.7.1')
SOLR_VERSION = "4.4.0"
SOLR = struct(
  :solr		=> solr_dependency('org.apache.solr:solr:war:'),
  :dataimport	=> solr_dependency('org.apache.solr:solr-dataimporthandler:jar:'),
  :cell		=> solr_dependency('org.apache.solr:solr-cell:jar:'),
  :dataextra	=> solr_dependency('org.apache.solr:solr-dataimporthandler-extras:jar:'),
  :velocity     => solr_dependency('org.apache.solr:solr-velocity:jar:')
)

SOLR_HOME = "ts-solr/solr-home/"
SOLR_LIB = "#{SOLR_HOME}lib/"
SOLR_WAR = "#{SOLR_LIB}solr-#{SOLR_VERSION}.war"
WAR_TEMP_DIR = 'target/solr/'

desc "Build Solr code for People Inquiry"

define "pi" do

  project.version = VERSION_NUMBER
  project.group = GROUP
  manifest["Implementation-Vendor"] = COPYRIGHT

  # Project compiles .class files from .java source files that are (by default) assumed to be
  # in src/main/java... to specify a different source dir use the compile.from method
  # to specify a different destination/target directory for the compiled files use the
  # compile.into method.

  # Add classpath dependencies
  compile.with JTDS, MYSQL, FLEXJSON, BSON4JACKSON, MONGO, SOLR.solr, SOLR.dataimport, SOLR.cell, SOLR.dataextra, XALAN, SOLR.velocity

  clean.enhance do
    FileUtils.rm_rf "#{SOLR_HOME}solr.war"
    FileUtils.rm_rf "#{SOLR_LIB}"
  end

  # Package custom GLG jars
  # patches for heirarchical multi-faceting and multi-prefixed facets
  package(:jar, :file=>_('target/glgrecommend.jar')).include('com/**').exclude('org/**').enhance do

    Dir::mkdir(SOLR_LIB) unless File.exists?(SOLR_LIB)
    compile.dependencies.map { |dep| FileUtils.cp dep.to_s , SOLR_LIB }

    #https://github.com/james75/SolrMongoImporter
    sh "cp lib/solr-mongo-importer.jar #{SOLR_LIB}solr-mongo-importer.jar"

    sh "cp #{SOLR_WAR} #{SOLR_HOME}solr.war"
  end

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
