require_relative 'base'
require_relative 'translators'

module OpenBEL
  module Helpers

    def render_evidence_collection(
      name, page_results, start, size, filters,
      filtered_total, collection_total
    )
      # see if the user requested a BEL translator (Accept header or ?format)
      translator        = Translators.requested_translator(request, params)
      translator_plugin = Translators.requested_translator_plugin(request, params)

      # Serialize to HAL if they [Accept]ed it, specified it as ?format, or
      # no translator was found to match request.
      if wants_default? || !translator
        evidence          = page_results[:cursor].map { |item|
          item.delete('facets')
          item
        }.to_a

        facets            = page_results[:facets]

        halt 404 if evidence.empty?

        pager = Pager.new(start, size, filtered_total)

        options = {
          :facets   => facets,
          :start    => start,
          :size     => size,
          :filters  => filters,
          :metadata => {
            :collection_paging => {
              :total                  => collection_total,
              :total_filtered         => pager.total_size,
              :total_pages            => pager.total_pages,
              :current_page           => pager.current_page,
              :current_page_size      => evidence.size,
            }
          }
        }

        # pager links
        options[:previous_page] = pager.previous_page
        options[:next_page]     = pager.next_page

        render_collection(evidence, :evidence, options)
      else
        extension = translator_plugin.file_extensions.first

        response.headers['Content-Type'] = translator_plugin.media_types.first
        status 200
        attachment "#{name}.#{extension}"
        stream :keep_open do |response|
          cursor             = page_results[:cursor]
          dataset_evidence = cursor.lazy.map { |evidence|
            evidence.delete('facets')
            evidence.delete('_id')
            evidence = keys_to_symbols(evidence)
            BEL::Model::Evidence.create(evidence)
          }

          translator.write(dataset_evidence, response)
        end
      end
    end

    def keys_to_symbols(obj)
      case obj
        when Array
          obj.inject([]) {|new_array, v|
            new_array << keys_to_symbols(v)
            new_array
          }
        when Hash
          obj.inject({}) {|new_hash, (k, v)|
            new_hash[k.to_sym] = keys_to_symbols(v)
            new_hash
          }
        else
          obj
      end
    end
  end
end