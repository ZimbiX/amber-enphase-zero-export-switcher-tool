# frozen_string_literal: true

require 'httpx'

module Zest
  module Enphase
    class Client
      def initialize(logger:, enphase_auth:, envoy_base_url:)
        @logger = logger
        @enphase_auth = enphase_auth
        @envoy_base_url = envoy_base_url
      end

      def set_current_grid_profile(name:)
        response = http.put(set_grid_profile_url, json: { selected_profile: name })
        response.raise_for_status
      end

      def installer_home
        response =  http.get(installer_home_url)
        response.raise_for_status
      end

      private

      attr_reader :logger, :enphase_auth, :envoy_base_url

      def http
        HTTPX
          .with_headers('Accept' => 'application/json')
          .then(&enphase_auth.method(:httpx_add_auth))
          .with(ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
      end

      def set_grid_profile_url
        "#{envoy_base_url}/installer/agf/set_profile.json"
      end

      def installer_home_url
        "#{envoy_base_url}/installer/setup/home"
      end
    end
  end
end
