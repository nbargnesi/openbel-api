require_relative '../spec_helper'
require 'json'

describe 'API Nanopub - Annotations' do

  subject(:nanopub_api) {
    root_resource(:nanopub)
  }

  it 'stores name/value annotation as-is (free annotation)' do
    example = JSON.load(test_file('annotation.json'))
    example['nanopub']['experiment_context'] << {
      'name'  => 'Species',
      'value' => '9606'
    }

    post_and_get(example, '/api/nanopubs') do |response|
      resource = response.body
      expect(resource).to                   include('nanopub')
      expect(resource['nanopub']).to       be_a(Hash)
      expect(resource['nanopub']).to       include('experiment_context')

      expect(resource['nanopub']['experiment_context']).to include(
        {
          'name'  => 'Species',
          'value' => '9606'
        }
      )
    end
  end

  it 'normalizes name/value annotation names (free annotation)' do
    example = JSON.load(test_file('annotation.json'))
    example['nanopub']['experiment_context'] = [
      {
        'name'  => 'status_value',
        'value' => '1'
      },
      {
        'name'  => 'Status-Value',
        'value' => '3'
      }
    ]

    post_and_get(example, '/api/nanopubs') do |response|
      resource = response.body
      expect(resource).to                   include('nanopub')
      expect(resource['nanopub']).to       be_a(Hash)
      expect(resource['nanopub']).to       include('experiment_context')

      expect(resource['nanopub']['experiment_context']).to include(
        {'name' => 'StatusValue', 'value' => '1'},
        {'name' => 'StatusValue', 'value' => '3'}
      )
    end
  end

  it 'normalizes name/value annotation to URI (structured annotation)' do
    example = JSON.load(test_file('annotation.json'))
    example['nanopub']['experiment_context'] = [
      {
        'name'  => 'Taxon',
        'value' => '9606'
      }
    ]

    post_and_get(example, '/api/nanopubs') do |response|
      resource = response.body
      expect(resource).to                   include('nanopub')
      expect(resource['nanopub']).to       be_a(Hash)
      expect(resource['nanopub']).to       include('experiment_context')

      expect(resource['nanopub']['experiment_context']).to include(
        {
          'name'  => 'Ncbi Taxonomy',
          'value' => 'Homo sapiens',
          'uri'   => "#{api_root}/annotations/taxon/values/9606"
        }
      )
    end
  end

  it 'normalizes resource URI to equivalent URI (structured annotation)' do
    example = JSON.load(test_file('annotation.json'))
    example['nanopub']['experiment_context'] = [
      {
        'uri' => "#{api_root}/annotations/taxon/values/9606"
      }
    ]

    post_and_get(example, '/api/nanopubs') do |response|
      resource = response.body
      expect(resource).to                   include('nanopub')
      expect(resource['nanopub']).to       be_a(Hash)
      expect(resource['nanopub']).to       include('experiment_context')

      expect(resource['nanopub']['experiment_context']).to include(
        {
          'name'  => 'Ncbi Taxonomy',
          'value' => 'Homo sapiens',
          'uri'   => "#{api_root}/annotations/taxon/values/9606"
        }
      )
    end
  end

  it "maps an annotation's RDF URI to an API URI" do
    example = JSON.load(test_file('annotation.json'))
    example['nanopub']['experiment_context'] = [
      {
        'uri' => 'http://www.openbel.org/bel/namespace/ncbi-taxonomy/9606'
      }
    ]

    post_and_get(example, '/api/nanopubs') do |response|
      resource = response.body
      expect(resource).to                   include('nanopub')
      expect(resource['nanopub']).to       be_a(Hash)
      expect(resource['nanopub']).to       include('experiment_context')

      expect(resource['nanopub']['experiment_context']).to include(
        {
          'name'  => 'Ncbi Taxonomy',
          'value' => 'Homo sapiens',
          'uri'   => "#{api_root}/annotations/taxon/values/9606"
        }
      )
    end
  end
end
