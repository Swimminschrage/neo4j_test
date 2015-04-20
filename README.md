# neo4j_test_server
Auto-starts a local Neo4j instance for running integration tests

## How to install

Install this neo4j_test_server from rubygems either directly:

```bash
gem install neo4j_test_server
```

Or through bundler

```ruby
# in Gemfile
gem "neo4j_test_server"
```

In `spec_helper.rb`

```
require 'sunspot_test/rspec'
```

## What does it do?

This gem will automatically startup a Neo4j server running locally for testing purposes.  The default server starts at
[http://localhost:7474](http://localhost:7474).

The gem also provides rspec hooks for tests that require Neo4j without requiring the server to be started for all of
your tests.

## Writing test that use Neo4jTestServer

In `spec_helper.rb`
```ruby
require 'neo4j_test_server'
require 'neo4j_test_server/rspec'
```

Then in your specs, tag the specs that require a neo4j server with 'neo4j: true'

```ruby
describe 'My Tests' do
    describe 'using neo4j', neo4j: true do

    end

    describe 'neo4j unnecessary' do

    end
end
```
