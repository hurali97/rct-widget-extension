#!/usr/bin/env ruby

require_relative './utils'

isLocalEnv = Dir.exist?('example')

puts "Do you want to automatically update the Podfile? (Y/N)"
response = gets.chomp.downcase

if response == 'y'
  update_conversions(isLocalEnv)
  update_graphics_conversions(isLocalEnv)

  warn("\nAdding TodayWidgetExtension target & dependencies to the Podfile\n")
  update_podfile(isLocalEnv)
elsif response == 'n'
  update_conversions(isLocalEnv)
  update_graphics_conversions(isLocalEnv)
else
  info("Invalid response. Please enter Y or N.")
end
