require_relative './test_helper'

class TestDeliverArgs < MiniTest::Unit::TestCase
  @version_format = /v\d\.\d\.\d/

  deliver(
    :args   => "-v",
    :output => @version_format
  )

  deliver(
    :args   => "--version",
    :output => @version_format
  )

  deliver(
    :args   => "-h",
    :output => "Deliver Manual"
  )

  deliver(
    :args   => "--help",
    :output => "Deliver Manual"
  )

  deliver(
    :args   => "-0",
    :output => "Unknown argument -0"
  )

  @strategies = "gh-pages.*nodejs.*ruby"

  deliver(
    :args   => "strategies",
    :output => /#{@strategies}/m
  )

  deliver(
    :args   => "-s foobar",
    :output => /strategy does not exist.*#{@strategies}/m,
    :status => 1
  )

  deliver(
    :args   => "check",
    :output => %r{
      APP.+deliver.+
      APP_ROOT.+deliver.+
      STRATEGY.+ruby.+
      CAN'T.DELIVER
    }xm,
    :status => 1
  )

  deliver(
    :vars   => "SERVER='localhost'",
    :args   => "check",
    :output => %r{
      APP.+deliver.+
      APP_ROOT.+deliver.+
      STRATEGY.+ruby.+
      SERVERS.+[^,]localhost[^,].+
      READY.TO.DELIVER
    }xm
  )
end
