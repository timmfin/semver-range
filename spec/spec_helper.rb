require 'simplecov'

converage_env_var = ENV["COVERAGE"]

if converage_env_var.nil? or converage_env_var != "false"
  SimpleCov.start do
    add_filter "/vendor/"
  end
end
