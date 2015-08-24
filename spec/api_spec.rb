require_relative 'spec_helper'

describe 'elasticsearch client' do
  let(:servers) { ['http://127.0.0.1:9200'] }

  subject do
    ElasticSearch::Client.new(servers: servers)
  end

  it 'returns meta' do
    subject.meta.must_be_instance_of Hash
  end

  it 'returns available?' do
    subject.available?.must_equal true
  end

  it 'returns available?' do
    subject.available?.must_equal true
  end

  it 'can fetch the indices' do
    subject.get_aliases.must_be_instance_of Hash
  end

  it 'can create an index' do
    with_temporary_index do |index_name|
      subject.get_aliases.keys.must_include index_name
    end
  end

  it 'can delete an index' do
    with_temporary_index do |index_name|
      subject.remove_index index_name
      subject.get_aliases.keys.wont_include index_name
    end
  end

  it 'can check for the existence of an index' do
    with_temporary_index do |index_name|
      subject.indices_exists?(index_name).must_equal true
      subject.remove_index index_name
      subject.indices_exists?(index_name).must_equal false
    end

  end

  it 'can update and get a mapping' do
    mapping =  {
      "foo" => {
        "properties" => {
          "bar" => { "type" => "string", "store" => true }
        }
      }
    }

    with_temporary_index do |index_name|
      response = subject.put_mapping index_name, 'foo', mapping
      response["acknowledged"].must_equal true

      response = subject.get_mapping index_name, 'foo'
      response[index_name]["mappings"].must_equal mapping
    end
  end

  def with_temporary_index(&blk)
    index_name = "test_index_#{Time.now.to_i}"

    begin
      response = subject.create_index index_name
      response["acknowledged"].must_equal true

      yield index_name
    ensure
      if subject.indices_exists?(index_name)
        response = subject.remove_index index_name
        response["acknowledged"].must_equal true
      end
    end

  end

end
