#!/usr/bin/env ruby

require_relative './utils'
require_relative './embed_widget_template'

_isLocalEnv = Dir.exist?('example')

def update_files(isLocalEnv, widget_target_name)
  update_conversions(isLocalEnv)
  update_graphics_conversions(isLocalEnv)

  warn("\nAdding TodayWidgetExtension target & dependencies to the Podfile\n")
  update_podfile(isLocalEnv, widget_target_name)
end


if _isLocalEnv == false
  puts "Name of the widget extension target (e.g., TodayWidgetExtension) ?"
  widget_target_name = gets.chomp

  if widget_target_name.empty?
    error("Widget target name cannot be empty.")
    exit 1
  end

  puts "Path to your App.xcodeproj (e.g., ./ios/App.xcodeproj) ?"
  target_project_path = gets.chomp

  if target_project_path.empty?
    error("Target project path cannot be empty.")
    exit 1
  end

  puts "Bundle Identifier of your app target (e.g., org.demo.app) ?"
  app_target_bundle_identifier = gets.chomp

  if app_target_bundle_identifier.empty?
    error("Bundle Identifier cannot be empty.")
    exit 1
  end

  embed_widget_target(target_project_path, widget_target_name, app_target_bundle_identifier)

  puts "Do you want to automatically update the Podfile? (Y/N)"
  response = gets.chomp.downcase

  if response == 'y'
    update_files(_isLocalEnv, widget_target_name)
  elsif response == 'n'
    update_conversions(_isLocalEnv)
    update_graphics_conversions(_isLocalEnv)
  else
    info("Invalid response. Please enter Y or N.")
  end
else
  update_files(_isLocalEnv)
end
