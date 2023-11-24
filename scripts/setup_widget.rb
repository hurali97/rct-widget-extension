#!/usr/bin/env ruby

require 'optparse'
require 'json'
require_relative './utils'
require_relative './embed_widget_template'

options = {}

opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: setup_widget [options]'

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

def parse_widget_config(_isLocalEnv, options)
  # Specify the path to your JSON file
  json_file_path = './widget.config.json'

  # Read the contents of the JSON file
  json_data = File.read(json_file_path)
    
  # Parse the JSON data
  parsed_data = JSON.parse(json_data)

  target_project_path = parsed_data['main']['targetProjectPath']
  app_target_bundle_identifier = parsed_data['main']['appTargetBundleIdentifier']

  widgets_from_config = parsed_data['widgets']

  # Get the keys
  widget_targets = widgets_from_config.keys

  # Now you can iterate over the keys or access them as needed
  widget_targets.each do |key|
    widget_details = widgets_from_config[key]
    widget_target_name = key
    embed_widget_target(target_project_path, app_target_bundle_identifier, widget_target_name, widget_details)
    if options[:updatePodfile]
      update_files(_isLocalEnv, widget_target_name)
    else
      update_conversions(_isLocalEnv)
      update_graphics_conversions(_isLocalEnv)
    end
  end
end


def update_files(_isLocalEnv, widget_target_name)
  update_conversions(_isLocalEnv)
  update_graphics_conversions(_isLocalEnv)

  warn("\nAdding WidgetExtension target & dependencies to the Podfile\n")
  update_podfile(_isLocalEnv, widget_target_name)
end


if isLocalEnv == false
  parse_widget_config(isLocalEnv, options)
else
  update_files(isLocalEnv, nil)
end
