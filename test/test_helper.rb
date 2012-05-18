require 'pry'
require 'colorize'

require 'turn/autorun'

TEST_PATH = File.expand_path("../", __FILE__)

class MiniTest::Unit::TestCase
  def self.deliver(opts={})
    options = {
      :args   => "",
      :status => 0
    }.merge(opts)


    command = "#{options[:vars]} deliver #{options[:args]} -T".strip.squeeze(' ')

    result = OpenStruct.new(
      :output => %x{#{command}}.chomp,
      :status => $?.exitstatus
    )

    name = options[:args].gsub(/[-\s]/,'')

    define_method "test_#{name}" do
      puts command.cyan
      assert_match(options[:output], result.output)
      assert_equal(options[:status], result.status)
    end
  end
end

%x{
  mkdir #{TEST_PATH}/tmp
}

MiniTest::Unit.after_tests do
  %x{
    rm -fr #{TEST_PATH}/tmp
  }
end
