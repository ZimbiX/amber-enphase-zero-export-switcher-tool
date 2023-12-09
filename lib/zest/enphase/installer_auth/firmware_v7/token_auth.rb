# frozen_string_literal: true

require 'httpx'

module Zest
  module Enphase
    module InstallerAuth
      module FirmwareV7
        class TokenAuth
          def initialize(logger:, token_manager:)
            @logger = logger
            @token_manager = token_manager
          end

          def httpx_add_auth(httpx)
            httpx
              .plugin(:authentication)
              .authentication("Bearer #{token_manager.token}")
          end

          private

          attr_reader :logger, :token_manager
        end
      end
    end
  end
end
