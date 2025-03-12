# frozen_string_literal: true

require 'httpx'
require 'jwt'
require 'nokogiri'

# Manages the token-based authentication used by an Envoy on firmware v7

module Zest
  module Enphase
    module InstallerAuth
      module FirmwareV7
        class TokenManager
          def initialize(logger:, enlighten_username:, enlighten_password:, envoy_serial:)
            @logger = logger
            @enlighten_username = enlighten_username
            @enlighten_password = enlighten_password
            @envoy_serial = envoy_serial
          end

          def token
            token_fresh? ? @token : refresh_token
          end

          private

          def token_fresh?
            return false unless @token
            Time.now < token_best_before
          end

          # Two minutes before expiry
          def token_best_before
            token_expires_at - 120
          end

          def token_expires_at
            payload, header = JWT.decode(@token, nil, false)
            Time.at(payload.fetch('exp'))
          end

          def refresh_token
            # Log in, storing session cookie
            logger.info('Need to refresh Enphase token; Logging into Entrez...')
            login_response = http.post(
              'https://entrez.enphaseenergy.com/login',
              form: {
                'username' => enlighten_username,
                'password' => enlighten_password,
              },
            )
            login_response.raise_for_status

            # Generate token
            logger.info('Requesting new token from Entrez...')
            token_page_response = http.post(
              'https://entrez.enphaseenergy.com/entrez_tokens',
              form: {
                # 'uncommissioned' => 'on',
                # 'Site' => '',
                'serialNum' => envoy_serial,
              },
            )
            token_page_response.raise_for_status

            document = Nokogiri::HTML(token_page_response.body.to_s)
            @token = document.at('#JWTToken').text
            logger.info('Enphase token refreshed')
            write_token_to_file
            @token
          end

          def http
            @http ||= HTTPX.plugin(:cookies)
          end

          def write_token_to_file
            File.write(token_file_path, @token)
          end

          def token_file_path
            '.enphase_token'
          end

          attr_reader :logger, :enlighten_username, :enlighten_password, :envoy_serial
        end
      end
    end
  end
end
