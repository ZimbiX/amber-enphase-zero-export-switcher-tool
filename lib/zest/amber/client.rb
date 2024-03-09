# frozen_string_literal: true

require 'httpx'

module Zest
  module Amber
    class Client
      def initialize(logger:, site_id:, token:)
        @logger = logger
        @site_id = site_id
        @token = token
      end

      CurrentPrices = Struct.new(:import, :export, keyword_init: true)
      CurrentPrice = Struct.new(:nem_time_end_at, :cents_per_kwh, keyword_init: true)

      # A negative price means you are earning
      def current_prices(resolution: 30)
        response = http.get("#{site_url}/prices/current", params: { resolution: })
        response.raise_for_status
        prices_data = JSON.parse(response.body.to_s)
        price_data_by_channel = prices_data.map { |price_data| [price_data.fetch('channelType'), price_data] }.to_h
        import_price_data = price_data_by_channel.fetch('general')
        export_price_data = price_data_by_channel.fetch('feedIn')
        import_price = CurrentPrice.new(
          nem_time_end_at: import_price_data.fetch('nemTime'),
          cents_per_kwh: import_price_data.fetch('perKwh'),
        )
        export_price = CurrentPrice.new(
          nem_time_end_at: export_price_data.fetch('nemTime'),
          cents_per_kwh: export_price_data.fetch('perKwh'),
        )
        CurrentPrices.new(import: import_price, export: export_price)
      end

      def costs_me_to_export?
        cost = current_prices.export.cents_per_kwh
        logger.info("Amber says exporting energy to the grid would currently #{cost > 0 ? 'cost' : 'earn'} me: #{cost.abs} c/kWh")
        cost > 0
      end

      private

      attr_reader :logger, :site_id, :token

      def http
        @http ||=
          HTTPX
            .with_headers('Accept' => 'application/json')
            .plugin(:auth)
            .bearer_auth(token)
            #.plugin(:persistent)
      end

      def site_url
        "#{base_url}/v1/sites/#{site_id}"
      end

      def base_url
        'https://api.amber.com.au'
      end
    end
  end
end
