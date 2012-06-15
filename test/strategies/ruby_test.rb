require_relative '../test_helper'

class TestDeliverRubyStrategy < MiniTest::Unit::TestCase
  deliver(
    :output => %r{
      init_app_remotely.\(\)
    }xm
  )
end
