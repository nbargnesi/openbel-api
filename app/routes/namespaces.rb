require 'cgi'
require 'multi_json'
require 'uri'

module OpenBEL
  module Routes

    # REST API for retrieving namespaces and values.  Provides the following capabilities:
    #
    # * Retrieve namespaces.
    # * Retrieve values for a namespace using the identifier, preferred name, or title.
    # * Retrieve equivalences for one or more values.
    # * Retrieve equivalences in a target namespace for one or more values.
    # * Retrieve orthologs for one or more values.
    # * Retrieve orthologs in a target namespace for one or more values.
    class Namespaces < Base

      RESULT_TYPES = {
        :resource => :all,
        :name => :prefLabel,
        :identifier => :identifier,
        :title => :title
      }

      def initialize(app)
        super
        @api = OpenBEL::Settings["namespace-api"].create_instance
      end

      options '/api/namespaces' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/equivalents' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/namespaces/:namespace/orthologs' do
        response.headers['Allow'] = 'OPTIONS,POST,GET'
        status 200
      end

      options '/api/namespaces/:namespace/:id' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/:id/equivalents' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/:id/equivalents/:target' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/:id/orthologs' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      options '/api/namespaces/:namespace/:id/orthologs/:target' do
        response.headers['Allow'] = 'OPTIONS,GET'
        status 200
      end

      get '/api/namespaces/?' do
        namespaces = @api.find_namespaces

        halt 404 if not namespaces or namespaces.empty?

        render_collection(
          namespaces.sort { |x,y|
            x.prefLabel.to_s <=> y.prefLabel.to_s
          },
          :namespace
        )
      end

      get '/api/namespaces/values/match-results/:match' do |match|
        start    = (params[:start]  || 0).to_i
        size     = (params[:size]   || 0).to_i

        faceted  = as_bool(params[:faceted])
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        halt 501 if faceted or not filter_params.empty?

        match_results = @api.search(match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render(
          match_results,
          :match_result_collection
        )
      end

      get '/api/namespaces/:namespace/?' do |namespace|
        ns = @api.find_namespace(namespace)

        halt 404 unless ns

        status 200
        render(
          ns,
          :namespace
        )
      end

      get '/api/namespaces/:namespace/values/match-results/:match' do |namespace, match|
        start    = (params[:start]  || 0).to_i
        size     = (params[:size]   || 0).to_i

        faceted  = as_bool(params[:faceted])
        filter_params = CGI::parse(env["QUERY_STRING"])['filter']
        halt 501 if faceted or not filter_params.empty?

        match_results = @api.search_namespace(namespace, match,
          :start => start,
          :size => size
        ).to_a

        halt 404 if not match_results or match_results.empty?
        render(
          match_results,
          :match_result_collection
        )
      end

      get '/api/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_equivalents(namespace, values, options)
        halt 404 if eq_mapping.values.all? { |v| v == nil }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump eq_mapping
      end

      post '/api/namespaces/:namespace/equivalents/?' do |namespace|
        halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

        content = request.body.read
        halt 400 if content.empty?

        params = Hash[
          URI.decode_www_form(content).group_by(&:first).map{
            |k,a| [k,a.map(&:last)]
          }
        ]

        halt 400 unless params['value']

        options = {}
        if params['namespace']
          options[:target] = params['namespace'].first
        end

        if params['result']
          result = params['result'].first.to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        eq_mapping = @api.find_equivalents(namespace, params['value'], options)
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump eq_mapping
      end

      get '/api/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.params['value']

        values = CGI::parse(env["QUERY_STRING"])['value']
        options = {}
        if request.params['namespace']
          options[:target] = request.params['namespace']
        end

        if request.params['result']
          result = request.params['result'].to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        orth_mapping = @api.find_orthologs(namespace, values, options)
        halt 404 if orth_mapping.values.all? { |v| v == nil }
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump orth_mapping
      end

      post '/api/namespaces/:namespace/orthologs/?' do |namespace|
        halt 400 unless request.media_type == 'application/x-www-form-urlencoded'

        content = request.body.read
        halt 400 if content.empty?

        params = Hash[
          URI.decode_www_form(content).group_by(&:first).map{
            |k,a| [k,a.map(&:last)]
          }
        ]

        halt 400 unless params['value']

        options = {}
        if params['namespace']
          options[:target] = params['namespace'].first
        end

        if params['result']
          result = params['result'].first.to_sym
          halt 400 unless RESULT_TYPES.include? result
          options[:result] = RESULT_TYPES[result]
        end

        orth_mapping = @api.find_orthologs(namespace, params['value'], options)
        response.headers['Content-Type'] = 'application/json'
        MultiJson.dump orth_mapping
      end

      get '/api/namespaces/:namespace/:id/?' do |namespace, value|
        value = @api.find_namespace_value(namespace, value)

        halt 404 unless value

        status 200
        render(
          value,
          :namespace_value
        )
      end

      get '/api/namespaces/:namespace/:id/equivalents/?' do |namespace, value|
        equivalents = @api.find_equivalent(namespace, value)
        halt 404 if not equivalents or equivalents.empty?

        render_collection(
          equivalents,
          :namespace_value
        )
      end

      get '/api/namespaces/:namespace/:id/equivalents/:target/?' do |namespace, value, target|
        equivalents = @api.find_equivalent(namespace, value, {
          target: target
        })
        halt 404 if not equivalents or equivalents.empty?

        render_collection(
          equivalents,
          :namespace_value
        )
      end

      get '/api/namespaces/:namespace/:id/orthologs/?' do |namespace, value|
        orthologs = @api.find_ortholog(namespace, value)
        halt 404 if not orthologs or orthologs.empty?

        render_collection(
          orthologs,
          :namespace_value
        )
      end

      get '/api/namespaces/:namespace/:id/orthologs/:target/?' do |namespace, value, target|
        orthologs = @api.find_ortholog(namespace, value, {
          target: target
        })
        halt 404 if not orthologs or orthologs.empty?

        render_collection(
          orthologs,
          :namespace_value
        )
      end
    end
  end
end
# vim: ts=2 sw=2:
# encoding: utf-8
