require 'bundler'
Bundler.setup

require 'pry'
require 'colorize'

require 'turn/autorun'

def shell(command)
  puts command.cyan
  `#{command}`.chomp
end
