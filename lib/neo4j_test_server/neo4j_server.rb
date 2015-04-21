require 'neo4j_test_server/java'
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

    attr_accessor :edition

    attr_writer :neo4j_data_dir, :neo4j_home, :neo4j_jar, :bind_address, :port

    def initialize(ed = 'community-2.2.0')
      ensure_java_installed
      self.edition = ed
    end

    def to_s
      "http://#{bind_address}:#{port}" unless bind_address.empty? && port.empty?
    end

    def bootstrap
      unless @bootstrapped
        Neo4jTest::Installer.bootstrap edition
        @bootstrapped = true
      end
    end

    def bind_address
      @bind_address ||= '127.0.0.1'
    end

    def port
      @port ||= '7474'
    end

    def start_command
      @start_command ||= 'start'
    end

    def start
      bootstrap

      puts 'Starting Neo4j...'
      if OS::Underlying.windows?
        start_windows_server(start_command)
      else
        start_starnix_server(start_command)
      end
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

    def ensure_java_installed
      unless defined?(@java_installed)
        @java_installed = Neo4jTest::Java.installed?
        unless @java_installed
          raise JavaMissing.new('You need a Java Runtime Environment to run the Solr server')
        end
      end
      @java_installed
    end

    def install_location
      Neo4jTest::Installer.install_location
    end
  end
end