# frozen_string_literal: true

require 'link_thumbnailer/model'

module LinkThumbnailer
  module Models
    class Website < ::LinkThumbnailer::Model

      attr_accessor :url, :title, :description, :images, :videos, :favicon, :body

      def initialize
        @images = []
        @videos = []
        @first_image = nil
      end

      def first_image
        return @first_image if @first_image.present?

        image = images.first
        return unless image

        @first_image = download_with_proxy(image.src)
      end

      def video=(video)
        self.videos = video
      end

      def videos=(videos)
        Array(videos).each do |video|
          @videos << video
        end
      end

      def image=(image)
        self.images = image
      end

      def images=(images)
        Array(images).each do |image|
          next unless image.valid?
          @images << image
        end
      end

      def images
        @images.sort!
      end

      def as_json(*)
        {
          url:          url.to_s,
          favicon:      favicon,
          title:        title,
          description:  description,
          images:       images.map(&:as_json),
          videos:       videos.map(&:as_json)
        }
      end

      private

      def download_with_proxy(url, proxy: nil)
        Down.open(
          url,
          proxy: proxy,
          max_size: 10.megabytes
        )
      rescue StandardError => e
        if proxy.present?
          download_with_proxy(url)
        else
          raise
        end
      end

    end
  end
end
