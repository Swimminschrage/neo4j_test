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
require 'neo4j_test_server/rspec'
```

## What does it do?

This gem will automatically startup a Neo4j server running locally for testing purposes.  The default server starts at
[http://localhost:7474](http://localhost:7474).

This gem also provides rspec hooks for tests that require Neo4j without requiring the server to be started for all of
your tests.

By default, the gem will download and run the "Community-2.2.0" version of Neo4j, see below for changing the edition
used.

## Writing tests that use Neo4jTestServer

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

## Using a different version of Neo4j

Before your tests run, call
```ruby
require 'neo4j_test_server'

Neo4jTestServer.edition = 'community-2.0.4' # Or whatever version you'd like to use
```
