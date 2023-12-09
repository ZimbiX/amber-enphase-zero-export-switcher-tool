# frozen_string_literal: true

require 'httpx'

module Zest
  module Enphase
    module InstallerAuth
      module FirmwareV5
        class CredentialsAuth
          def initialize(logger:, envoy_installer_username:, envoy_installer_password:)
            @logger = logger
            @envoy_installer_username = envoy_installer_username
            @envoy_installer_password = envoy_installer_password
          end

          def httpx_add_auth(httpx)
            httpx
              .plugin(:digest_authentication)
              .digest_auth(envoy_installer_username, envoy_installer_password)
          end

          private

          attr_reader :logger, :envoy_installer_username, :envoy_installer_password
        end
      end
    end
  end
end
