require 'neo4j_test_server'
require 'rspec'

RSpec.configure do |c|
  c.before(:each, neo4j: true) do
    puts 'Running using actual Neo4j instance....'
    Neo4jTestServer.setup_neo4j
    #TODO: Add any cleanup that should happen between tests

    # Configure this statement to match the url for the local Neo4j instance.
    Neo4j::Session.open(:server_db, 'http://127.0.0.1:7474')

    # Delete all nodes/relationships from the grid
    Neo4jTestServer.clear_db
  end
end