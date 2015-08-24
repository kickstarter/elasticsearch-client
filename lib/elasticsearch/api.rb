module ElasticSearch
  module API
    # Create a new index in elasticsearch
    #
    #   name           - the name of the index to be created
    #   create_options - a hash of index creation options
    def create_index(index, create_options={})
      #resp = put do |req|
      #  req.url "/#{index}"
      #  req.body = create_options
      #end
      resp = post "/#{index}", create_options
      resp.body
    end

    # Delete an index in elasticsearch
    #
    #   index - the name of the index
    def remove_index(index)
      resp = delete do |req|
        req.url "#{index}"
      end
      resp.body
    end

    # Close an index in elasticsearch
    #
    #   index - the name of the index
    def close_index(index)
      resp = post do |req|
        req.url "#{index}/_close"
      end
      resp.body
    end

    # Open an index in elasticsearch
    #
    #   index - the name of the index
    def open_index(index)
      resp = post do |req|
        req.url "#{index}/_open"
      end
      resp.body
    end

    # Force a refresh of an index
    #
    # This basically tells elasticsearch to flush its buffers
    # but not clear caches (unlike a commit in Solr)
    # "Commits" happen automatically and are managed by elasticsearch
    #
    #   index - the name of the index
    #
    # Returns a hash, the parsed response body from elasticsearch
    def refresh(indexes)
      resp = post "/#{Array(indexes).join(',')}/_refresh"
      resp.body
    end

    def indices_exists?(indices)
      resp = head "/#{Array(indices).join(',')}"
      resp.status == 200
    end

    def bulk(data, query_params={})
      return if data.empty?
      url = Faraday.build_url("_bulk", query_params).request_uri
      resp = post url, data
      raise ResponseError, "bulk import got HTTP #{resp.status} response" if resp.status != 200
      resp.body
    end

    # Grab a bunch of items from an index
    #
    #   index - the name of the index
    #   type  - the type to pull from
    #   ids   - an Array of ids to fetch
    #
    # Returns a hash, the parsed response body from elasticsearch
    def mget(index, type, ids)
      resp = get do |req|
        req.url "#{index}/#{type}/_mget"
        req.body = {'ids' => ids}
      end
      resp.body
    end

    # Search an index using a post body
    #
    #   index   - the name of the index
    #   types   - the type or types (comma seperated) to search
    #   options - options hash for this search request
    #
    # Returns a hash, the parsed response body from elasticsearch
    def search(index, types, options)
      resp = get do |req|
        req.url "#{index}/#{types}/_search"
        req.body = options
      end
      resp.body
    end

    # Search an index using a query string
    #
    #   index   - the name of the index
    #   types   - the type or types (comma seperated) to search
    #   query   - the search query string
    #   options - options hash for this search request (optional)
    #
    # Returns a hash, the parsed response body from elasticsearch
    def query(index, types, query, options=nil)
      query = {'q' => query} if query.is_a?(String)
      resp = get do |req|
        req.url "#{index}/#{types}/_search", query
        req.body = options if options
      end
      resp.body
    end

    # Count results using a query string
    #
    #   index   - the name of the index
    #   types   - the type or types (comma seperated) to search
    #   query   - the search query string
    #   options - options hash for this search request (optional)
    #
    # Returns a hash, the parsed response body from elasticsearch
    def count(index, types, query, options=nil)
      query = {'q' => query} if query.is_a?(String)
      resp = get do |req|
        req.url "#{index}/#{types}/_count", query
        req.body = options if options
      end
      resp.body
    end

    # Add a document to an index
    #
    #   index   - the name of the index
    #   type    - the type of this document
    #   id      - the unique identifier for this document
    #   doc     - the document to be indexed
    #
    # Returns a hash, the parsed response body from elasticsearch
    def add(index, type, id, doc, params={})
      doc.each do |key, val|
        # make sure dates are in a consistent format for indexing
        doc[key] = val.iso8601 if val.respond_to?(:iso8601)
      end

      resp = put do |req|
        req.url "/#{index}/#{type}/#{id}", params
        req.body = doc
      end
      resp.body
    end

    # Remove a document from an index
    #
    #   index - the name of the index
    #   type  - the type of document to be removed
    #   id    - the unique identifier of the document to be removed
    #
    # Returns a hash, the parsed response body from elasticsearch
    def remove(index, type, id)
      resp = delete do |req|
        req.url "#{index}/#{type}/#{id}"
      end
      resp.body
    end

    # Remove all of a type from an index
    #
    #   index - the name of the index
    #   type  - the type of document to be removed
    #
    # Returns a hash, the parsed response body from elasticsearch
    def remove_all(index, type)
      resp = delete do |req|
        req.url "#{index}/#{type}/_query", :q => '*'
      end
      resp.body
    end

    # Remove a collection of documents matched by a query
    #
    #   index   - the name of the index
    #   types   - the type or types to query
    #   options - the search options hash
    #
    # Returns a hash, the parsed response body from elasticsearch
    def remove_by_query(index, types, options)
      resp = delete do |req|
        req.url "#{index}/#{types}/_query"
        req.body = options
      end
      resp.body
    end

    # Fetch the mappings defined for an index
    #
    #   index   - the name of the index
    #   types   - the type or types to query
    #
    # Returns a hash, the parsed response body from elasticsearch
    def get_mapping(index, types)
      path = if version_is_at_least("1.0")
        "#{index}/_mapping/#{types}"
      else
        "#{index}/#{types}/_mapping"
      end

      resp = get do |req|
        req.url path
      end
      resp.body
    end

    # Adds mappings to an index
    #
    #   index   - the name of the index
    #   type    - the type we're modifying
    #   mapping - the new mapping to merge into the index
    #
    # Returns a hash, the parsed response body from elasticsearch
    def put_mapping(index, type, mapping)
      path = if version_is_at_least("1.0")
        "#{index}/_mapping/#{type}"
      else
        "#{index}/#{type}/_mapping"
      end

      resp = put do |req|
        req.url path
        req.body = mapping
      end
      resp.body
    end

    # Gets aliases
    #
    # Returns a hash, the parsed response body from elasticsearch
    def get_aliases
      resp = get do |req|
        req.url "/_aliases"
      end
      resp.body
    end

    # Add alias
    #
    #   index    - the name of the index
    #   alias    - the alias we're adding
    #
    # Returns a hash, the parsed response body from elasticsearch
    def add_alias(index, alias_name)
      post_aliases [{ :add => { :index => index, :alias => alias_name }}]
    end

    # Remove alias
    #
    #   index    - the name of the index
    #   alias    - the alias we're removing
    #
    # Returns a hash, the parsed response body from elasticsearch
    def remove_alias(index, alias_name)
      post_aliases [{ :remove => { :index => index, :alias => alias_name }}]
    end

    # Post alias actions
    #
    #   actions  - an array of hashes with alias actions to perform
    #
    # Returns a hash, the parsed response body from elasticsearch
    def post_aliases(actions)
      resp = post do |req|
        req.url "/_aliases"
        req.body = { :actions => Array.new(actions) }
      end
      resp.body
    end

    # Analyze a string
    #
    #   data - string to analyze
    #   options - analyzer options such as {tokenizer: :standard}
    #
    # Returns a hash, the parsed response body from elasticsearch
    def analyze(data, options = {})
      resp = get do |req|
        req.url "/_analyze", options
        req.body = data
      end
      resp.body
    end

    # Is the cluster responding?
    #
    # Returns a boolean
    def available?
      resp = get do |req|
        req.url '/'
      end
      resp.status == 200
    end

    # Info about this ES cluster
    #
    # Returns a hash, for example:
    # {
    #   "status" : 200,
    #   "name" : "my_node_name",
    #   "cluster_name" : "my_elasticsearch_cluster",
    #   "version" : {
    #     "number" : "1.7.1",
    #     "build_hash" : "abc123",
    #     "build_timestamp" : "2015-01-01T00:00:00Z",
    #     "build_snapshot" : false,
    #     "lucene_version" : "4.10.4"
    #   },
    #   "tagline" : "You Know, for Search"
    # }
    def meta
      resp = get do |req|
        req.url '/'
      end
      resp.body
    end

    # Initiates or continues a scrolling scan of the index.
    #
    # On the initial call a cursor (`_scroll_id`) is acquired, along with the first page of
    # results. On subsequent calls, pass in this cursor to get the next "page" of results.
    #
    # Scans can be created with a "timeout", which is how long ElasticSearch will keep
    # the results of the scan around. Subsequent calls with a timeout refresh the timeout.
    #
    # You can also specify how many results are returned *per server*. For example, if you
    # have 5 servers, and specify 10 results, each page will return 50 results.
    def scroll(index, types, options: nil, cursor: nil, timeout: '1m', results_per_server: 1000)
      if !cursor
        resp = get do |req|
          req.url "#{index}/#{types}/_search", {
            scroll: timeout,
            search_type: :scan,
            size: results_per_server
          }

          req.body = options if options
        end
        return scroll(index, types, cursor: resp.body['_scroll_id'], timeout: timeout)
      end

      resp = get do |req|
        req.url '_search/scroll', {
          scroll: timeout,
          scroll_id: cursor
        }
      end
      resp.body
    end

  end
end
