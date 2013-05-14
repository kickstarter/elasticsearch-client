require_relative 'spec_helper'

describe 'elasticsearch client' do
  let(:servers) { ['http://127.0.0.1:9200'] }

  subject do
    ElasticSearch::Client.new(servers: servers)
  end

  it 'is available' do
    subject.available?.must_equal true
  end

  it 'should be due for refresh after init' do
    subject.should_refresh?.must_equal true
  end

  it 'defaults to seed servers when fetching' do
    subject.fetch_servers.must_equal servers
  end

  it 'fetches custom server list' do
    custom_servers = ['http://localhost:9200']
    subject.fetch_servers = Proc.new { custom_servers }

    subject.refresh_servers
    subject.servers.must_equal custom_servers
  end

  describe 'with a short timeout' do
    subject { ElasticSearch::Client.new(servers: servers, timeout: 0.000001) }
    it 'should raise a timeout error' do
      -> { subject.get("/") }.must_raise ElasticSearch::ConnectionFailed
    end
  end
end
