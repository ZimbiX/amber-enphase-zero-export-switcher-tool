# frozen_string_literal: true

require 'spec_helper'

require 'green_log'

require 'zest/amber/client'

RSpec.describe Zest::Amber::Client do
  subject(:client) do
    described_class.new(logger: GreenLog::Logger.null, site_id: 'some-site-id', token: 'some-api-token')
  end

  describe '#current_prices' do
    subject(:current_prices) { client.current_prices }

    let(:response) { instance_double(HTTPX::Response, body: response_body) }
    let(:response_body) { instance_double(HTTPX::Response::Body, to_s: parsed_body.to_json) }
    let(:parsed_body) do
      [
        {
          'type' => 'CurrentInterval',
          'date' => '2022-12-27',
          'duration' => 30,
          'startTime' => '2022-12-27T07:30:01Z',
          'endTime' => '2022-12-27T08:00:00Z',
          'nemTime' => '2022-12-27T18:00:00+10:00',
          'perKwh' => 31.50177,
          'renewables' => 32.449,
          'spotPerKwh' => 10.79744,
          'channelType' => 'general',
          'spikeStatus' => 'none',
          'descriptor' => 'low',
          'estimate' => false
        },
        {
          'type' => 'CurrentInterval',
          'date' => '2022-12-27',
          'duration' => 30,
          'startTime' => '2022-12-27T07:30:01Z',
          'endTime' => '2022-12-27T08:00:00Z',
          'nemTime' => '2022-12-27T18:00:00+10:00',
          'perKwh' => -10.67878,
          'renewables' => 32.449,
          'spotPerKwh' => 10.79744,
          'channelType' => 'feedIn',
          'spikeStatus' => 'none',
          'descriptor' => 'high',
          'estimate' => false
        }
      ]
    end

    before do
      allow_any_instance_of(HTTPX::Session).to receive(:get).and_return(response)
    end

    it 'returns a CurrentPrices struct containing CurrentPrice structs with the correct data' do
      expect(current_prices).to eq(
        Zest::Amber::Client::CurrentPrices.new(
          import: Zest::Amber::Client::CurrentPrice.new(
            nem_time_end_at: '2022-12-27T18:00:00+10:00',
            cents_per_kwh: 31.50177,
          ),
          export: Zest::Amber::Client::CurrentPrice.new(
            nem_time_end_at: '2022-12-27T18:00:00+10:00',
            cents_per_kwh: -10.67878,
          ),
        )
      )
    end
  end
end
