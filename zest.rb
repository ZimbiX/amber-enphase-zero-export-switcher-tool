#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'bundler/setup'

require 'dotenv/load'
require 'green_log'

require 'zest/amber/client'
require 'zest/enphase/client'
require 'zest/enphase/manager'
require 'zest/enphase/installer_auth/firmware_v5/credentials_auth'
require 'zest/enphase/installer_auth/firmware_v7/token_auth'
require 'zest/enphase/installer_auth/firmware_v7/token_manager'

logger = GreenLog::Logger.build(severity_threshold: ENV.fetch('ZEST_LOG_LEVEL'))

STDOUT.sync = true

enphase_auth =
  case ENV.fetch('ZEST_ENPHASE_ENVOY_FIRMWARE_VERSION')
  when '4', '5'
    Zest::Enphase::InstallerAuth::FirmwareV5::CredentialsAuth.new(
      logger:,
      envoy_installer_username: ENV.fetch('ZEST_ENPHASE_ENVOY_INSTALLER_USERNAME'),
      envoy_installer_password: ENV.fetch('ZEST_ENPHASE_ENVOY_INSTALLER_PASSWORD'),
    )
  when '7'
    token_manager = Zest::Enphase::InstallerAuth::FirmwareV7::TokenManager.new(
      logger:,
      enlighten_username: ENV.fetch('ZEST_ENPHASE_ENLIGHTEN_USERNAME'),
      enlighten_password: ENV.fetch('ZEST_ENPHASE_ENLIGHTEN_PASSWORD'),
      envoy_serial: ENV.fetch('ZEST_ENPHASE_ENVOY_SERIAL'),
    )
    Zest::Enphase::InstallerAuth::FirmwareV7::TokenAuth.new(
      logger:,
      token_manager:,
    )
  else
    raise 'Invalid ZEST_ENPHASE_ENVOY_FIRMWARE_VERSION: Must be 4, 5, or 7'
  end

amber_client = Zest::Amber::Client.new(
  logger:,
  site_id: ENV.fetch('ZEST_AMBER_SITE_ID'),
  token: ENV.fetch('ZEST_AMBER_TOKEN'),
)

envoy_ip = ENV.fetch('ZEST_ENPHASE_ENVOY_IP')
envoy_http_scheme = ENV.fetch('ZEST_ENPHASE_ENVOY_USE_HTTPS') == 'true' ? 'https' : 'http'
enphase_client = Zest::Enphase::Client.new(
  logger:,
  enphase_auth:,
  envoy_base_url: "#{envoy_http_scheme}://#{envoy_ip}",
)

enphase_manager = Zest::Enphase::Manager.new(
  logger:,
  enphase_client:,
  envoy_grid_profile_name_normal_export: ENV.fetch('ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_NORMAL_EXPORT'),
  envoy_grid_profile_name_zero_export: ENV.fetch('ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_ZERO_EXPORT'),
  status_file_path: ENV.fetch('ZEST_STATUS_FILE', nil),
  post_switch_custom_command: ENV.fetch('ZEST_COMMAND_TO_RUN_AFTER_SWITCHING_GRID_PROFILE', nil),
)

amber_poll_interval_seconds = Float(ENV.fetch('ZEST_AMBER_POLL_INTERVAL_SECONDS'))

loop do
  begin
    if amber_client.costs_me_to_export?
      enphase_manager.set_export_limit_to_zero
    else
      enphase_manager.set_export_limit_to_normal
    end
  rescue => e
    puts "Error: #{e}", e.backtrace
  end
  puts
  sleep amber_poll_interval_seconds
end
