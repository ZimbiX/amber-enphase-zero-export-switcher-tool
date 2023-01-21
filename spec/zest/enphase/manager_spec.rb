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

  def reset_mock(mock)
    RSpec::Mocks.space.proxy_for(mock).reset
  end

  shared_examples 'writes to the status file' do |expected_status_file_content|
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

  shared_examples 'does not write to the status file' do
    before do
      File.write(status_file_path_absolute, 'previous-content')
    end

    it 'does not write to the status file' do
      expect { subject }.not_to(
        change { File.read(status_file_path_absolute) }
          .from('previous-content')
      )
    end
  end

  shared_examples 'does not ask the Enphase client to set the current grid profile' do
    it 'does not ask the Enphase client to set the current grid profile' do
      subject
      expect(enphase_client).not_to have_received(:set_current_grid_profile)
    end
  end

  describe '#set_export_limit_to_normal' do
    subject(:set_export_limit_to_normal) do
      manager.set_export_limit_to_normal
    end

    shared_examples 'sets to normal' do
      it "asks the Enphase client to set the Envoy's grid profile to the normal export limit one" do
        set_export_limit_to_normal
        expect(enphase_client).to have_received(:set_current_grid_profile).with(name: envoy_grid_profile_name_normal_export)
      end

      it_behaves_like 'writes to the status file', 'normal'
    end

    context 'when the current grid profile is unknown' do
      it_behaves_like 'sets to normal'
    end

    context 'when the current grid profile is set to zero' do
      before { manager.set_export_limit_to_zero }

      it_behaves_like 'sets to normal'
    end

    context 'when the current grid profile is already set to normal' do
      before do
        manager.set_export_limit_to_normal
        reset_mock(enphase_client)
        allow(enphase_client).to receive(:set_current_grid_profile)
      end

      it_behaves_like 'does not write to the status file'
      it_behaves_like 'does not ask the Enphase client to set the current grid profile'
    end
  end

  describe '#set_export_limit_to_zero' do
    subject(:set_export_limit_to_zero) do
      manager.set_export_limit_to_zero
    end

    shared_examples 'sets to zero' do
      it "asks the Enphase client to set the Envoy's grid profile to the zero export limit one" do
        set_export_limit_to_zero
        expect(enphase_client).to have_received(:set_current_grid_profile).with(name: envoy_grid_profile_name_zero_export)
      end

      it_behaves_like 'writes to the status file', 'zero'
    end

    context 'when the current grid profile is unknown' do
      it_behaves_like 'sets to zero'
    end

    context 'when the current grid profile is set to normal' do
      before { manager.set_export_limit_to_normal }

      it_behaves_like 'sets to zero'
    end

    context 'when the current grid profile is already set to zero' do
      before do
        manager.set_export_limit_to_zero
        reset_mock(enphase_client)
        allow(enphase_client).to receive(:set_current_grid_profile)
      end

      it_behaves_like 'does not write to the status file'
      it_behaves_like 'does not ask the Enphase client to set the current grid profile'
    end
  end
end
