# frozen_string_literal: true

require 'spec_helper'

require 'zest/enphase/manager'

RSpec.describe Zest::Enphase::Manager do
  subject(:manager) do
    described_class.new
  end
end
