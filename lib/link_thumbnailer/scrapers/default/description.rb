# frozen_string_literal: true

require 'link_thumbnailer/scrapers/default/base'

module LinkThumbnailer
  module Scrapers
    module Default
      class Description < ::LinkThumbnailer::Scrapers::Default::Base

        def value
          return model_from_meta.to_s if model_from_meta
          return model_from_body.to_s if model_from_body
          nil
        end

        private

        def model_from_meta
          modelize(node_from_meta, node_from_meta.attributes['content'].value) if node_from_meta
        end

        def model_from_body
          return nil if candidates.size <= 1

          candidates.each_with_index.map { |node, i| modelize(node, node.text, i) }.sort.last
        end

        def node_from_meta
          @node_from_meta ||= meta_xpath(key: :name)
        end

        def candidates
          document.css('p,td')
        end

        def modelize(node, text, i = 0)
          model_class.new(node, text, i, candidates.count)
        end
      end
    end
  end
end
