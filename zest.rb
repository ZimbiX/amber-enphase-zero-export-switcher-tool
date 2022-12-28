#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)

require 'bundler/setup'

require 'dotenv/load'
require 'green_log'

require 'zest/amber/client'
require 'zest/enphase/client'
require 'zest/enphase/manager'

logger = GreenLog::Logger.build(severity_threshold: ENV.fetch('ZEST_LOG_LEVEL'))

STDOUT.sync = true

amber_client = Zest::Amber::Client.new(
  logger:,
  site_id: ENV.fetch('ZEST_AMBER_SITE_ID'),
  token: ENV.fetch('ZEST_AMBER_TOKEN'),
)

enphase_client = Zest::Enphase::Client.new(
  logger:,
  envoy_ip: ENV.fetch('ZEST_ENPHASE_ENVOY_IP'),
  envoy_installer_username: ENV.fetch('ZEST_ENPHASE_ENVOY_INSTALLER_USERNAME'),
  envoy_installer_password: ENV.fetch('ZEST_ENPHASE_ENVOY_INSTALLER_PASSWORD'),
)

enphase_manager = Zest::Enphase::Manager.new(
  logger:,
  enphase_client:,
  envoy_grid_profile_name_normal_export: ENV.fetch('ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_NORMAL_EXPORT'),
  envoy_grid_profile_name_zero_export: ENV.fetch('ZEST_ENPHASE_ENVOY_GRID_PROFILE_NAME_ZERO_EXPORT'),
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
