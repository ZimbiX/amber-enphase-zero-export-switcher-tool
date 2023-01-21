# frozen_string_literal: true

require 'spec_helper'

require 'green_log'

require 'zest/enphase/client'
require 'zest/enphase/manager'

RSpec.describe Zest::Enphase::Manager do
  subject(:manager) do
    described_class.new(
      logger: ,
      enphase_client:,
      envoy_grid_profile_name_normal_export:,
      envoy_grid_profile_name_zero_export:,
      status_file_path:,
    )
  end
  let(:logger) { GreenLog::Logger.null }
  let(:enphase_client) { instance_double(Zest::Enphase::Client, set_current_grid_profile: nil) }
  let(:envoy_grid_profile_name_normal_export) { 'gird-profile-name-normal-export' }
  let(:envoy_grid_profile_name_zero_export) { 'gird-profile-name-zero-export' }
  let(:status_file_path) { 'tmp/zest-status-file' }

  let(:status_file_path_absolute) { File.join(__dir__, '../../..', status_file_path) }

  shared_examples 'status file' do |expected_status_file_content|
    before do
      File.write(status_file_path_absolute, 'previous-content')
    end

    it 'writes the status to the status file, replacing the contents' do
      expect { subject }.to(
        change { File.read(status_file_path_absolute) }
          .from('previous-content')
          .to(expected_status_file_content)
      )
    end
  end

  describe '#set_export_limit_to_normal' do
    subject(:set_export_limit_to_normal) do
      manager.set_export_limit_to_normal
    end

    it_behaves_like 'status file', 'normal'
  end

  describe '#set_export_limit_to_zero' do
    subject(:set_export_limit_to_zero) do
      manager.set_export_limit_to_zero
    end

    it_behaves_like 'status file', 'zero'
  end
end
