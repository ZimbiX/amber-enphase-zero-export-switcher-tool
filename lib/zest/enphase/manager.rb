# frozen_string_literal: true

module Zest
  module Enphase
    class Manager
      def initialize(logger:, enphase_client:, envoy_grid_profile_name_normal_export:, envoy_grid_profile_name_zero_export:, status_file_path:, post_switch_custom_command:)
        @logger = logger
        @enphase_client = enphase_client
        @envoy_grid_profile_name_normal_export = envoy_grid_profile_name_normal_export
        @envoy_grid_profile_name_zero_export = envoy_grid_profile_name_zero_export
        @status_file_path = status_file_path
        @post_switch_custom_command = post_switch_custom_command

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
        write_status_to_file
        run_post_switch_custom_command
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
        write_status_to_file
        run_post_switch_custom_command
      end

      private

      def write_status_to_file
        return unless status_file_path && status_file_path.length > 0

        File.write(status_file_path, current_export_limit)
      end

      def run_post_switch_custom_command
        return unless post_switch_custom_command && post_switch_custom_command.length > 0

        logger.info('Running custom post-grid-profile-switch command...')
        system post_switch_custom_command
        if $?.success?
          logger.info("Custom post-grid-profile-switch command finished successfully")
        else
          logger.error("Custom post-grid-profile-switch command did not finish successfully")
        end
      end

      attr_reader :logger, :enphase_client, :envoy_grid_profile_name_normal_export, :envoy_grid_profile_name_zero_export, :status_file_path, :post_switch_custom_command

      attr_accessor :current_export_limit
    end
  end
end
