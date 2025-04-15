# frozen_string_literal: true

require 'link_thumbnailer/scrapers/default/base'

module LinkThumbnailer
  module Scrapers
    module Default
      class Title < ::LinkThumbnailer::Scrapers::Default::Base

        def value
          if model&.text.present?
            model.to_s
          else
            UrlTools.short_url(website.url)
          end
        end

        private

        def model
          modelize(node)
        end

        def node
          document.css(attribute_name)
        end

      end
    end
  end
end
