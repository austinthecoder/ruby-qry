require "bundler/setup"
require "qry"

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus

  config.warnings = false
end
