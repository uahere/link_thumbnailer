# frozen_string_literal: true

module LinkThumbnailer
  module Scrapers
    module Default
      module UrlTools
        module_function

        MAX_PATH_LENGTH = 40
        MAX_QUERY_LENGTH = 20
        ELLIPSIS = "..."

        def short_url(url)
          uri = Addressable::URI.parse(url).normalize
          path_parts = uri.path.split("/").reject(&:empty?)
          return uri.to_s.chomp("/") if path_parts.empty? && uri.query.nil?

          first_part = truncate_string(path_parts.first || "")
          last_part = truncate_string(path_parts.last || "")

          query_part = process_query(uri.query)

          short_path = path_parts.size > 2 ? "#{first_part}/#{ELLIPSIS}/#{last_part}" : last_part
          short_path += "?#{query_part}" if query_part.present?
          "#{uri.scheme}://#{uri.host}/#{short_path}"
        end

        def truncate_string(str, max_length = MAX_PATH_LENGTH)
          return str if str.length <= max_length

          "#{str[0, max_length - 3]}#{ELLIPSIS}"
        end

        def process_query(query)
          return if query.blank?

          query_params = URI.decode_www_form(query).reject { |key, _| key.start_with?("_") }
          first_query = query_params.first
          return unless first_query

          key, value = first_query
          query_string = "#{key}=#{value}"
          truncate_string(query_string, MAX_QUERY_LENGTH)
        end
      end
    end
  end
end
