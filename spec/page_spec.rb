# frozen_string_literal: true

require 'spec_helper'

describe LinkThumbnailer::Page do

  let(:url)       { 'http://foo.com' }
  let(:instance)  { described_class.new(url, options) }

  context 'with inline options' do

    let(:options) { { image_limit: 2 } }

    it { expect(instance.config.image_limit).to eq(2) }
    it { expect(instance.config.user_agent).to eq(LinkThumbnailer.config.user_agent) }
    it { expect(instance.config.accept_language).to eq(LinkThumbnailer.config.accept_language) }
    it { expect(instance.config.proxy).to eq(LinkThumbnailer.config.proxy) }
  end

  context 'without inline options' do

    let(:options) { {} }

    it { expect(instance.config.image_limit).to eq(LinkThumbnailer.config.image_limit) }
    it { expect(instance.config.user_agent).to eq(LinkThumbnailer.config.user_agent) }
    it { expect(instance.config.accept_language).to eq(LinkThumbnailer.config.accept_language) }
    it { expect(instance.config.proxy).to eq(LinkThumbnailer.config.proxy) }
  end

end
