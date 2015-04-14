require 'neo4j_test/java'
require 'os'
require 'httparty'
require 'zip'

module Neo4jTest
  class Server
    # Raised if #stop is called but the server is not running
    ServerError = Class.new(RuntimeError)
    AlreadyRunningError = Class.new(ServerError)
    NotRunningError = Class.new(ServerError)
    JavaMissing = Class.new(ServerError)

    attr_accessor :min_memory, :max_memory, :log_file, :edition

    attr_writer :pid_dir, :pid_file, :neo4j_data_dir, :neo4j_home, :neo4j_jar, :start_command, :bind_address, :port

    def initialize(*args)
      ensure_java_installed
      self.edition = 'community-2.2.0'
      super(*args)
    end

    def to_s
      "http://#{bind_address}:#{port}" unless bind_address.empty? && port.empty?
    end

    def bootstrap
      unless @bootstrapped
        download_neo4j_unless_exists(edition)
        unzip_neo4j
        rake_auth_toggle :disable
        @bootstrapped = true
      end
    end

    def file_name
      OS::Underlying.windows? ? 'neo4j.zip' : 'neo4j-unix.tar.gz'
    end

    def download_to
      file_name
    end

    def bind_address
      @bind_address ||= 'localhost'
    end

    def port
      @port ||= '7474'
    end

    def download_url(edition)
      "http://dist.neo4j.org/neo4j-#{edition}-#{OS::Underlying.windows? ? 'windows.zip' : 'unix.tar.gz'}"
    end

    def download_neo4j_unless_exists(edition)
      download_neo4j(edition) unless File.exist?(file_name)
      download_to
    end

    def download_neo4j(edition)
      success = false

      File.open(download_to, 'wb') do |file|
        file << request_url(download_url(edition))
        success = true
      end

      download_to
    ensure
      File.delete(file_name) unless success
    end

    def unzip_neo4j
      downloaded_file = download_to

      if OS::Underlying.windows?
        # Extract and move to neo4j directory
        unless File.exist?(install_location)
          Zip::ZipFile.open(downloaded_file) do |zip_file|
            zip_file.each do |f|
              f_path = File.join('.', f.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              begin
                zip_file.extract(f, f_path) unless File.exist?(f_path)
              rescue
                puts "#{f.name} failed to extract."
              end
            end
          end
          FileUtils.mv "neo4j-#{edition}", install_location
          #FileUtils.rm downloaded_file
        end

        # Install if running with Admin Privileges
        if `reg query "HKU\\S-1-5-19"`.size > 0
          `"#{install_location}/bin/neo4j install"`
          puts 'Neo4j Installed as a service.'
        end

      else
        `tar -xvf #{downloaded_file}`
        `mv neo4j-#{edition} #{install_location}`
        #`rm #{downloaded_file}`
        puts 'Neo4j Installed in to neo4j directory.'
      end
    end

    def request_url(url)
      status = HTTParty.head(url).code
      fail "#{edition} is not available to download, try a different version" if status < 200 || status >= 300

      HTTParty.get(url)
    end

    def get_environment
      'development'
    end

    def install_location
      path = File.expand_path('../../../tmp/db/neo4j', __FILE__)
      FileUtils.mkdir_p(path)
      "#{path}/#{get_environment}"
    end

    def config_location
      "#{install_location}/conf/neo4j-server.properties"
    end

    def start_command
      @start_command ||= 'start'
    end

    def start
      bootstrap

      puts "Starting Neo4j #{get_environment}..."
      if OS::Underlying.windows?
        start_windows_server(start_command)
      else
        start_starnix_server(start_command)
      end
    end

    def start_windows_server(command)
      if `reg query "HKU\\S-1-5-19"`.size > 0
        `#{install_location}/bin/Neo4j.bat #{command}`  # start service
      else
        puts 'Starting Neo4j directly, not as a service.'
        `#{install_location}/bin/Neo4j.bat`
      end
    end

    def start_starnix_server(command)
      `#{install_location}/bin/neo4j #{command}`
    end

    def stop
      if OS::Underlying.windows?
        if `reg query "HKU\\S-1-5-19"`.size > 0
          `#{install_location}/bin/Neo4j.bat stop`  # stop service
        else
          puts 'You do not have administrative rights to stop the Neo4j Service'
        end
      else
        `#{install_location}/bin/neo4j stop`
      end
    end

    def ensure_java_installed
      unless defined?(@java_installed)
        @java_installed = Neo4jTest::Java.installed?
        unless @java_installed
          raise JavaMissing.new('You need a Java Runtime Environment to run the Solr server')
        end
      end
      @java_installed
    end

    def rake_auth_toggle(status)
      location = config_location
      text = File.read(location)
      replace = toggle_auth(status, text)
      File.open(location, 'w') { |file| file.puts replace }
    end

    def config(source_text, port)
      s = set_property(source_text, 'org.neo4j.server.webserver.https.enabled', 'false')
      set_property(s, 'org.neo4j.server.webserver.port', port)
    end

    def set_property(source_text, property, value)
      source_text.gsub(/#{property}\s*=\s*(\w+)/, "#{property}=#{value}")
    end

    # Toggles the status of Neo4j 2.2's basic auth
    def toggle_auth(status, source_text)
      status_string = status == :enable ? 'true' : 'false'
      %w(dbms.security.authorization_enabled dbms.security.auth_enabled).each do |key|
        source_text = set_property(source_text, key, status_string)
      end
      source_text
    end
  end
end