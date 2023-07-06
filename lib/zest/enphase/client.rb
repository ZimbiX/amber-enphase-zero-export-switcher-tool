# frozen_string_literal: true

require 'httpx'

module Zest
  module Enphase
    class Client
      def initialize(logger:, envoy_ip:, envoy_installer_username:, envoy_installer_password:)
        @logger = logger
        @envoy_ip = envoy_ip
        @envoy_installer_username = envoy_installer_username
        @envoy_installer_password = envoy_installer_password
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

      attr_reader :logger, :envoy_ip, :envoy_installer_username, :envoy_installer_password

      def http
        @http ||=
          HTTPX
            .with_headers('Accept' => 'application/json')
            .plugin(:digest_authentication)
            .digest_auth(envoy_installer_username, envoy_installer_password)
            .plugin(:persistent)
            .with(ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
      end

      def set_grid_profile_url
        "#{base_url}/installer/agf/set_profile.json"
      end

      def installer_home_url
        "#{base_url}/installer/setup/home"
      end

      def base_url
        "https://#{envoy_ip}"
      end
    end
  end
end
