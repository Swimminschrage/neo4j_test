require 'neo4j'
require 'net/http'
require 'neo4j_test_server/neo4j_server'
require 'neo4j_test_server/installer'

# Based off of the setup uses for SunspotTest
module Neo4jTestServer
  class TimeoutError < StandardError; end
  class << self
    attr_writer :neo4j_startup_timeout
    attr_writer :server

    def neo4j_startup_timeout
      @neo4j_startup_timeout ||= 30
    end

    def setup_neo4j
      start_neo4j_server
    end

    def start_neo4j_server
      unless neo4j_running?
        server.start

        at_exit do
          puts "Shutting down Neo4j server at '#{server}'"
          server.stop
        end

        wait_for_server
      end
    end

    def wait_for_server
      (neo4j_startup_timeout * 10).times do
        break if neo4j_running?
        sleep(0.1)
      end
      raise TimeoutError, "Neo4j failed to startup after #{neo4j_startup_timeout} seconds." unless neo4j_running?
      puts "Neo4j Running at '#{server}'"
    end

    def neo4j_running?
      begin
        Net::HTTP.get(URI.parse(ping_url))
        true
      rescue
        false # Neo4j not running
      end
    end

    def ping_url
      "http://#{server.bind_address}:#{server.port}"
    end

    def server
      @server ||= Neo4jTest::Server.new
    end

    def session
      return nil unless neo4j_running?

      @session ||= Neo4j::Session.open(:server_db, ping_url)
    end

    def clear_db
      session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end

  end

end