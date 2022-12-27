# frozen_string_literal: true

module Zest
  module Enphase
    class Manager
      def initialize(logger:, enphase_client:, envoy_grid_profile_name_normal_export:, envoy_grid_profile_name_zero_export:)
        @logger = logger
        @enphase_client = enphase_client
        @envoy_grid_profile_name_normal_export = envoy_grid_profile_name_normal_export
        @envoy_grid_profile_name_zero_export = envoy_grid_profile_name_zero_export

        @current_export_limit = :unknown
      end

      def set_export_limit_to_normal
        if current_export_limit == :normal
          logger.info('Export limit is already set to normal')
          return
        end
        logger.info('Making HTTP request to set export limit to normal...')
        enphase_client.set_current_grid_profile(name: envoy_grid_profile_name_normal_export)
        logger.info('Request complete')
        @current_export_limit = :normal
      end

      def set_export_limit_to_zero
        if current_export_limit == :zero
          logger.info('Export limit is already set to zero')
          return
        end
        logger.info('Making HTTP request to set export limit to zero...')
        enphase_client.set_current_grid_profile(name: envoy_grid_profile_name_zero_export)
        logger.info('Request complete')
        @current_export_limit = :zero
      end

      private

      attr_reader :logger, :enphase_client, :envoy_grid_profile_name_normal_export, :envoy_grid_profile_name_zero_export

      attr_accessor :current_export_limit
    end
  end
end
