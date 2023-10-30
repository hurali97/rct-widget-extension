#!/usr/bin/env ruby

require 'optparse'
require_relative './utils'
require_relative './embed_widget_template'

options = {}

opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: setup_widget [options]'

  opts.on('--widgetTargetName WIDGET_TARGET_NAME', 'Name of the widget extension target (e.g., TodayWidgetExtension)') do |widget_target_name|
    options[:widgetTargetName] = widget_target_name
  end

  opts.on('--xcodeProjectPath XCODE_PROJECT_PATH', 'Path to your App.xcodeproj (e.g., ./ios/App.xcodeproj)') do |xcode_project_path|
    options[:xcodeProjectPath] = xcode_project_path
  end

  opts.on('--bundleID BUNDLE_ID', 'Specify the bundle ID') do |bundle_id|
    options[:bundleID] = bundle_id
  end

  opts.on('--updatePodfile BOOLEAN', 'Specify whether to update Podfile (true/false)') do |update_podfile|
    options[:updatePodfile] = update_podfile.downcase == 'true'
  end

  opts.on('-h', '--help', 'Print this help') do
    puts opts
    exit
  end
end

opt_parser.parse!

isLocalEnv = Dir.exist?('example')

def update_files(_isLocalEnv, widget_target_name)
  update_conversions(_isLocalEnv)
  update_graphics_conversions(_isLocalEnv)

  warn("\nAdding TodayWidgetExtension target & dependencies to the Podfile\n")
  update_podfile(_isLocalEnv, widget_target_name)
end


if isLocalEnv == false
  unless options.key?(:widgetTargetName)
    error("Widget target name can not be empty.")
    exit 1
  end
  widget_target_name = options[:widgetTargetName]

  unless options.key?(:xcodeProjectPath)
    error("Xcode project path can not be empty.")
    exit 1
  end
  target_project_path = options[:xcodeProjectPath]

  unless options.key?(:bundleID)
    error("Bundle Identifier can not be empty.")
    exit 1
  end
  app_target_bundle_identifier = options[:bundleID]

  embed_widget_target(target_project_path, widget_target_name, app_target_bundle_identifier)

  if options[:updatePodfile]
    update_files(_isLocalEnv, widget_target_name)
  else
    update_conversions(isLocalEnv)
    update_graphics_conversions(isLocalEnv)
  end
else
  update_files(isLocalEnv)
end
