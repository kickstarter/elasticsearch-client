require 'elasticsearch/api'

module ElasticSearch
  class Client
    include ElasticSearch::API

    attr_accessor :current_server, :fetch_servers, :seed_servers, :servers, :refreshed_at, :refresh_period, :timeout

    def initialize(args = {})
      args = defaults.merge(args)
      @fetch_servers = args[:fetch_servers] # Proc returning array of server strings
      @refresh_period = args[:refresh_period] # Seconds before refreshing list of servers
      @seed_servers = Array(args[:servers])
      @timeout = args[:timeout]
    end

    def defaults
      {
        refresh_period: 60,
        servers: ['http://127.0.0.1:9200'],
        timeout: 2
      }
    end

    %w(head get post put delete).each do |method|
      class_eval <<-EOC, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          begin
            refresh_servers if should_refresh?
            response = connection.#{method}(*args, &block)
            raise ConnectionFailed, "elasticsearch server is offline or not accepting requests" if response.status == 0
            raise ResponseError, response.body if response.body['error']
            response
          rescue Faraday::Error::ConnectionFailed, Faraday::Error::TimeoutError, ConnectionFailed => e
            drop_current_server!
            raise ConnectionFailed, $!
          end
        end
      EOC
    end

    def refresh_servers
      @seed_servers = fetch_servers
      @servers = @seed_servers.clone
      @current_server = @servers.first
      @refreshed_at = Time.now
      @version = nil
      @connection = nil
    end

    # Returns the major/minor version
    def version
      @version ||= Gem::Version.new(meta['version']['number'])
    end

    def version_is_at_least(other_version)
      version >= Gem::Version.new(other_version)
    end

    def fetch_servers
      if @fetch_servers
        servers = @fetch_servers.call
        servers.length > 0 ? servers : @seed_servers
      else
        @seed_servers
      end
    end

    def should_refresh?
      return true unless servers
      return (servers.length == 0) || (Time.now > refreshed_at + refresh_period)
    end

    def current_server
      @current_server ||= servers.first
    end

    def connection
      @connection ||= Faraday.new(url: current_server, request: {timeout: @timeout}) do |builder|
        builder.request  :json
        builder.response :json, :content_type => /\bjson$/
        builder.adapter :excon
      end
    end

    def drop_current_server!
      @servers.delete(current_server)
      @current_server = nil
      @connection = nil
    end
  end
end
