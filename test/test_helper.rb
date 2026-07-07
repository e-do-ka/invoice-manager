ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # 並列実行でテストを高速化
    parallelize(workers: :number_of_processors)
  end
end
