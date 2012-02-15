require 'bundler'
Bundler.setup

require 'minitest/unit'
require 'minitest/spec'

require 'turn/colorize'
require 'turn/controller'
require 'turn/runners/minirunner'

Turn.config do |config|
  config.format = :pretty
end

MiniTest::Unit.runner = Turn::MiniRunner.new
MiniTest::Unit.autorun

require 'pry'
require 'colorize'

def shell(command)
  puts command.cyan
  `#{command}`.chomp
end
