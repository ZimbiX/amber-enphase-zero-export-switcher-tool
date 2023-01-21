# frozen_string_literal: true

module Zest
  module Enphase
    class Manager
      def initialize(logger:, enphase_client:, envoy_grid_profile_name_normal_export:, envoy_grid_profile_name_zero_export:, status_file_path:)
        @logger = logger
        @enphase_client = enphase_client
        @envoy_grid_profile_name_normal_export = envoy_grid_profile_name_normal_export
        @envoy_grid_profile_name_zero_export = envoy_grid_profile_name_zero_export
        @status_file_path = status_file_path

        @current_export_limit = :unknown
      end

      def set_export_limit_to_normal
        if current_export_limit == :normal
          logger.info('Export limit is already set to normal')
          return
        end
        logger.info('Making HTTP request to set export limit to normal...')
        enphase_client.set_current_grid_profile(name: envoy_grid_profile_name_normal_export)
        write_status_to_file('normal')
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
        write_status_to_file('zero')
        logger.info('Request complete')
        @current_export_limit = :zero
      end

      private

      def write_status_to_file(status)
        File.write(status_file_path, status)
      end

      attr_reader :logger, :enphase_client, :envoy_grid_profile_name_normal_export, :envoy_grid_profile_name_zero_export, :status_file_path

      attr_accessor :current_export_limit
    end
  end
end
