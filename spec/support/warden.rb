# frozen_string_literal: true

RSpec.configure do |config|
  config.include Warden::Test::Helpers

  config.after(:each, type: :system) do
    Warden.test_reset!
  end
end
