# ElasticSearch Ruby Client

Ruby client for ElasticSearch. Credit goes to my coworkers at GitHub; I just turned it into a gem.

## Usage

Add to Gemfile

    gem 'elasticsearch-client', :require => 'elasticsearch'

Create client:

    client = ElasticSearch::Client.new

Create index:

    index = 'twitter'
    client.create_index(index)

Index a document:

    type = 'tweet'
    doc = {:id => 'abcd', :foo => 'bar'}
    client.add(index, type, doc[:id], doc)

Get a document:

    id = '1234'
    client.mget(index, type, [id])

Get documents:

    id2 = 'abcd'
    client.mget(index, type, [id, id2])

Search:

    query = {
      :query => {
        :match_all => {}
      }
    }
    client.search(index, type, query)

Remove record:

    client.remove(index, type, id)

Remove by query:

    client.remove_by_query(index, type, :term => {:foo => 'bar'})

Remove all of type:

    client.remove_all(index, type)

Create alias:

    client.add_alias(index, alias_name)

Remove alias:

    client.remove_alias(index, alias_name)

Post alias actions:

    client.post_aliases([
      {:remove => {:index => index, :alias => old_alias_name}},
      {:add => {:index => index, :alias => new_alias_name}}
    ])

Create client using multiple servers:

    servers = ['http://127.0.0.1:9200', 'http://127.0.0.1:10200']
    client = ElasticSearch::Client.new(:servers => servers)

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so we don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine, but bump version in a commit by itself so we can ignore when we pull)
* Send us a pull request. Bonus points for topic branches.
