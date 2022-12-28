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
        http.put(set_grid_profile_url, json: { selected_profile: name })
      end

      def installer_home
        http.get(installer_home_url)
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
      end

      def set_grid_profile_url
        "#{base_url}/installer/agf/set_profile.json"
      end

      def installer_home_url
        "#{base_url}/installer/setup/home"
      end

      def base_url
        "http://#{envoy_ip}"
      end
    end
  end
end
