VERSION_NUMBER = "1.0.0"
GROUP = "Search & Recommendations"
# TODO: Need to automate resolution of (c) date to be 2012 - currentyear()
COPYRIGHT = "(c) 2012 - Gerson Lehrman Group"

# Specify Maven 2.0 remote repositories here, like this:
repositories.remote << "http://repo1.maven.org/maven2" << "http://www.ibiblio.org/maven2"

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
SOLR_VERSION = "4.0.0"
SOLR = struct(
  :solr		=> solr_dependency('org.apache.solr:solr:war:'),
  :dataimport	=> solr_dependency('org.apache.solr:solr-dataimporthandler:jar:'),
  :cell		=> solr_dependency('org.apache.solr:solr-cell:jar:'),
  :dataextra	=> solr_dependency('org.apache.solr:solr-dataimporthandler-extras:jar:'),
  :velocity     => solr_dependency('org.apache.solr:solr-velocity:jar:')
)

SOLR_HOME = 'ts-solr/solr-home/'

desc "Build Solr code for People Inquiry"

define "Pi-Solr" do

  project.version = VERSION_NUMBER
  project.group = GROUP
  manifest["Implementation-Vendor"] = COPYRIGHT

  # Project compiles .class files from .java source files that are (by default) assumed to be
  # in src/main/java... to specify a different source dir use the compile.from method
  # to specify a different destination/target directory for the compiled files use the
  # compile.into method.

  # Add classpath dependencies
  compile.with JTDS, MYSQL, FLEXJSON, BSON4JACKSON, MONGO, SOLR.solr, SOLR.dataimport, SOLR.cell, SOLR.dataextra, XALAN, SOLR.velocity

  # Package custom GLG jars
  # patches for heirarchical multi-faceting and multi-prefixed facets
  package(:jar, :file=>_('target/glgrecommend.jar')).include('com/**').exclude('org/**').enhance do

    filter.from('lib').into("#{SOLR_HOME}lib").include('solr-mongo-importer-1.0.0.jar').run
    compile.dependencies.map { |dep| FileUtils.cp dep.to_s , "#{SOLR_HOME}lib" }

    solr_war_temp_location = 'target/solr/'
    war_name = "solr-#{SOLR_VERSION}.war"
    solr_war = "#{SOLR_HOME}lib/solr-#{SOLR_VERSION}.war"

    FileUtils.mv 'ts-solr/solr-home/lib/' + war_name , solr_war_temp_location + war_name
    sh "unzip " + solr_war_temp_location + war_name + " -d " + solr_war_temp_location
    sh "cd target/classes; zip -r ../../ts-solr/solr-home/lib/temp/WEB-INF/lib/apache-solr-core-#{SOLR_VERSION}.jar org; cd ../.. "
    sh "cd ts-solr/solr-home/lib/temp; zip -r ../../solr.war *; cd ../../../.."
    FileUtils.rm_rf solr_war_temp_location
  end

  task :config_env do
    File.open('/home/nswarr/data-config.xml', 'w'){|f| f.write(xml.to_xml)}
  end

end