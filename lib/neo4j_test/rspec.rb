require 'neo4j_test'
require 'rspec'

RSpec.configure do |c|
  c.before(:each) do
    puts 'Running using Neo4j stub...'
    Neo4jTest.stub
  end

  c.before(:each, search: true) do
    puts 'Running using actual Neo4j instance....'
    Neo4jTest.unstub
    Neo4jTest.setup_neo4j
    #TODO: Add any cleanup that should happen between tests

    # Delete all nodes/relationships from the grid
    Neo4jTest.clear_db
  end
end