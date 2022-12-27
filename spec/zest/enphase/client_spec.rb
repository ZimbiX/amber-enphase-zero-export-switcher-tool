# frozen_string_literal: true

require 'spec_helper'

require 'zest/enphase/client'

RSpec.describe Zest::Enphase::Client do
  subject(:client) do
    described_class.new
  end
end
