require 'os'
require 'httparty'
require 'zip'

module Neo4jTest
  class Installer
    BadEditionError = Class.new(RuntimeError)

    class << self
      def bootstrap(edition)
        raise BadEditionError if edition.empty?

        download_neo4j_unless_exists edition
        unzip_neo4j edition
        rake_auth_toggle :disable
      end

      def file_name
        OS::Underlying.windows? ? 'neo4j.zip' : 'neo4j-unix.tar.gz'
      end

      def download_to
        file_name
      end

      def download_url(edition)
        "http://dist.neo4j.org/neo4j-#{edition}-#{OS::Underlying.windows? ? 'windows.zip' : 'unix.tar.gz'}"
      end

      def download_neo4j_unless_exists(edition)
        download_neo4j(edition) unless File.exist?(download_to)
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

      def unzip_neo4j(edition)
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
          end

          # Install if running with Admin Privileges
          if `reg query "HKU\\S-1-5-19"`.size > 0
            `"#{install_location}/bin/neo4j install"`
            puts 'Neo4j Installed as a service.'
          end

        else
          `tar -xvf #{downloaded_file}`
          `mv neo4j-#{edition} #{install_location}`
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
end