# frozen_string_literal: true

require 'delegate'
require 'uri'
require 'net/http/persistent'

module LinkThumbnailer
  class Processor < ::SimpleDelegator

    attr_accessor :url, :proxy
    attr_reader   :config, :http, :redirect_count

    def initialize
      @config = ::LinkThumbnailer.page.config
      @proxy  = config.proxy
      @proxy  = ::URI.parse(@proxy) if @proxy && @proxy != :ENV
      @http   = ::Net::HTTP::Persistent.new

      super(config)
    end

    def start(url)
      result = call(url)
      shutdown
      result
    end

    def call(url = '', redirect_count = 0, headers = {})
      self.url        = url
      @redirect_count = redirect_count

      raise ::LinkThumbnailer::RedirectLimit if too_many_redirections?

      with_valid_url do
        set_http_headers(headers)
        set_http_options
        perform_request
      end
    rescue ::Net::HTTPExceptions, ::Net::HTTPClientException, ::SocketError, ::Timeout::Error, ::Net::HTTP::Persistent::Error => e
      raise ::LinkThumbnailer::HTTPError.new(e.message)
    end

    private

    def shutdown
      http.shutdown
    end

    def with_valid_url
      raise ::LinkThumbnailer::BadUriFormat unless valid_url_format?
      yield if block_given?
    end

    def set_http_headers(headers = {})
      headers.each { |k, v| http.headers[k] = v }
      http.override_headers['User-Agent'] = user_agent
      http.override_headers['Accept-Language'] = accept_language
      config.http_override_headers.each { |k, v| http.override_headers[k] = v }
    end

    def set_http_options
      http.verify_mode  = ::OpenSSL::SSL::VERIFY_NONE unless ssl_required?
      http.open_timeout = http_open_timeout
      http.read_timeout = http_read_timeout
      http.proxy = ::URI.parse(proxy) if proxy && proxy != :ENV
    end

    def perform_request
      response = request_in_chunks

      # unless response.is_a?(::Net::HTTPClientException)
      #   headers           = {}
      #   headers['Cookie'] = response['Set-Cookie'] if response['Set-Cookie'].present?

      #   raise ::LinkThumbnailer::FormatNotSupported.new(response['Content-Type']) unless valid_response_format?(response)
      # end

      case response
      when ::Net::HTTPSuccess
        Response.new(response).body
      when ::Net::HTTPRedirection
        call(
          resolve_relative_url(response['location'].to_s),
          redirect_count + 1,
          headers
        )
      when ::Net::HTTPClientException
        if http.proxy_uri.is_a?(::URI::HTTP)
          http.proxy = nil
          perform_request
        else
          response.error!
        end
      else
        response.error!
      end
    end

    def request_in_chunks
      body     = String.new
      response = http.request(url) do |resp|
        raise ::LinkThumbnailer::DownloadSizeLimit if too_big_download_size?(resp.content_length)
        resp.read_body do |chunk|
          body.concat(chunk)
          raise ::LinkThumbnailer::DownloadSizeLimit if too_big_download_size?(body.length)
        end
      end
      response.body = body
      response
    rescue ::Net::HTTPExceptions, ::Net::HTTPClientException, ::SocketError, ::Timeout::Error, ::Net::HTTP::Persistent::Error => e
      response = ::Net::HTTPClientException.new(e.message, nil)
    end

    def resolve_relative_url(location)
      location.start_with?('http') ? location : build_absolute_url_for(location)
    end

    def build_absolute_url_for(relative_url)
      ::URI.parse("#{url.scheme}://#{url.host}#{relative_url}")
    end

    def redirect_limit
      config.redirect_limit
    end

    def user_agent
      config.user_agent
    end

    def accept_language
      config.accept_language
    end

    def proxy
      config.proxy
    end

    def http_open_timeout
      config.http_open_timeout
    end

    def http_read_timeout
      config.http_read_timeout
    end

    def ssl_required?
      config.verify_ssl
    end

    def download_size_limit
      config.download_size_limit
    end

    def too_many_redirections?
      redirect_count > redirect_limit
    end

    def valid_url_format?
      url.is_a?(::URI::HTTP)
    end

    def valid_response_format?(response)
      return true unless config.raise_on_invalid_format
      return true if response['Content-Type'] =~ /text\/html/
      return true if response['Content-Type'] =~ /application\/html/
      return true if response['Content-Type'] =~ /application\/xhtml\+xml/
      return true if response['Content-Type'] =~ /application\/xml/
      return true if response['Content-Type'] =~ /text\/xml/
      return true if response['Content-Type'] =~ /text\/plain/
      false
    end

    def too_big_download_size?(size)
      size.to_i > download_size_limit.to_i
    end

    def url=(url)
      @url = ::URI.parse(url.to_s)
    end

  end
end
