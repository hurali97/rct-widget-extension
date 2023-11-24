#!/usr/bin/env ruby
require 'rubygems'
require 'fileutils'
require 'xcodeproj'

def move_folder_recursively(source, destination)
  FileUtils.mkdir_p(destination) # Create the destination directory if it doesn't exist

  Dir.glob(File.join(source, '**', '*')).each do |item|
    next if ['.', '..'].include?(File.basename(item)) # Skip current and parent directory entries

    new_item = File.join(destination, item.sub(source, '')) # Calculate the new path for the item
    if File.directory?(item)
      FileUtils.mkdir_p(new_item) # Create the new directory
    else
      FileUtils.cp(item, new_item) # Move the file
    end
  end
end

def embed_widget_target(target_project_path, app_target_bundle_identifier, new_widget_target_name, widget_details)
  source_files = ['Info.plist', 'TemplateWidget.swift', 'TemplateWidgetBundle.swift']

  # Open the target Xcode project
  target_project = Xcodeproj::Project.open(target_project_path)

  # Create a new Widget Extension target in the target project
  new_widget_target = target_project.new_target(:app_extension, new_widget_target_name, :ios)

  # Create a new group within the project's main group for the Widget Extension files
  new_group_name = new_widget_target_name
  widget_group = target_project.main_group.new_group(new_group_name, new_group_name)

  # Create an array to store file_reference objects
  file_references = []

  ios_path = File.dirname(target_project_path)

  group_path = "#{ios_path}/#{new_group_name}"
  
  # Create the directory if it doesn't exist
  FileUtils.mkdir_p(group_path)

  # Add source files to the new Widget Extension target
  source_files.each do |source_file|
      source_path = File.join('node_modules/rct-widget-extension/template/TemplateWidget/', source_file)

      destination_file = source_file

      if (source_file == source_files[1])
        destination_file = "#{new_widget_target_name}.swift"
      elsif (source_file == source_files[2])
        destination_file = "#{new_widget_target_name}Bundle.swift"
      end
      
      destination_path = File.join(group_path, destination_file)
      FileUtils.copy(source_path, destination_path)
      
      file_content = File.read(destination_path)
      # Use gsub! to replace all occurrences of 'TemplateWidget' with the variable value
      file_content.gsub!('TemplateWidget', new_widget_target_name)

      # Write the modified content back to the file
      File.write(destination_path, file_content)

      if source_file == source_files[0]
        widget_group.new_reference(destination_file)
      else
        file_reference = widget_group.new_reference(destination_file)
        file_references << file_reference # Append the file_reference to the array
      end
  end

  new_widget_target.add_file_references(file_references)
  path_to_assets = "#{group_path}/Assets.xcassets"
  move_folder_recursively('node_modules/rct-widget-extension/template/TemplateWidget/Assets.xcassets', path_to_assets)

  # Create a new PBXContainerItemProxy for the new_widget_target
  container_item_proxy = target_project.new(Xcodeproj::Project::Object::PBXContainerItemProxy)
  container_item_proxy.container_portal = new_widget_target.uuid
  container_item_proxy.proxy_type = '1'  # Use '2' for target type (e.g., application extension)
  container_item_proxy.remote_info = new_widget_target_name

  # Add the PBXContainerItemProxy to the target project
  target_project.root_object.project_references.each do |reference|
    if reference['ProductGroup'] && reference['ProductGroup'].display_name == 'Products'
      reference['ProductGroup'].children << container_item_proxy
      break
    end
  end

  app_target = target_project.targets.first # Modify this to get your app target
  app_target.add_dependency(new_widget_target)


  # Locate the "Embed App Extensions" build phase
  embed_extensions_phase = nil
  app_target = nil

  # Use File.basename to get the filename with extension
  filename_with_extension = File.basename(target_project_path)

  # Use File.basename with an additional argument to strip the extension
  filename_without_extension = File.basename(filename_with_extension, '.*')

  target_name = filename_without_extension

  target_project.targets.each do |target|
    if target.name == target_name # Replace with your app target's name
      app_target = target
      embed_extensions_phase = target.copy_files_build_phases.find { |phase| phase.symbol_dst_subfolder_spec == :plug_ins }
      break
    end
  end

  # Ensure that the "Embed App Extensions" phase exists
  if embed_extensions_phase.nil?
    # If it doesn't exist, create a new one
    embed_extensions_phase = app_target.new_copy_files_build_phase('Embed Foundation Extensions')
    embed_extensions_phase.symbol_dst_subfolder_spec = :plug_ins
  end

  appex = new_widget_target.product_reference

  appex.name = "#{new_widget_target_name}.appex"
  appex.path = ".appex"
  build_file = embed_extensions_phase.add_file_reference(appex, true)
  build_file.settings = { "ATTRIBUTES" => ['RemoveHeadersOnCopy'] }

  # Update the Swift version for the new_widget_target
  swift_version = '5.0' # Specify the desired Swift version

  # Modify the build settings for the new_widget_target
  new_widget_target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = swift_version
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{app_target_bundle_identifier}.#{new_widget_target_name}"
    config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = "AccentColor";
    config.build_settings['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = "WidgetBackground";
    config.build_settings['CLANG_ANALYZER_NONNULL'] = "YES";
    config.build_settings['CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION'] = "YES_AGGRESSIVE";
    config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = "gnu++20";
    config.build_settings['CLANG_ENABLE_OBJC_WEAK'] = "YES";
    config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = "YES";
    config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = "YES_AGGRESSIVE";
    config.build_settings['CODE_SIGN_STYLE'] = "Automatic";
    config.build_settings['CURRENT_PROJECT_VERSION'] = "1";
    config.build_settings['DEBUG_INFORMATION_FORMAT'] = "dwarf";
    config.build_settings['GCC_C_LANGUAGE_STANDARD'] = "gnu11";
    config.build_settings['GENERATE_INFOPLIST_FILE'] = "YES";
    config.build_settings['INFOPLIST_FILE'] = "#{new_group_name}/Info.plist";
    config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = "#{new_widget_target_name}";
    config.build_settings['INFOPLIST_KEY_NSHumanReadableCopyright'] = "";
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = "16.4";
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
      "$(inherited)",
      "@executable_path/Frameworks",
      "@executable_path/../../Frameworks",
    ];
    config.build_settings['MARKETING_VERSION'] = "1.0";
    config.build_settings['MTL_ENABLE_DEBUG_INFO'] = "INCLUDE_SOURCE";
    config.build_settings['MTL_FAST_MATH'] = "YES";
    config.build_settings['PRODUCT_NAME'] = "$(TARGET_NAME)";
    config.build_settings['SKIP_INSTALL'] = "YES";
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = "DEBUG";
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = "YES";
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = "-Onone";
    config.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2";
  end

  # Define the frameworks to link (SwiftUI and WidgetKit)
  frameworks_to_link = ['SwiftUI', 'WidgetKit']

  # Add the frameworks to the "Link Binaries With Libraries" build phase
  frameworks_to_link.each do |framework|
      path = "System/Library/Frameworks/#{framework}.framework"
      framework_ref = target_project.frameworks_group.new_reference(path)
      framework_ref.name = "#{framework}.framework"
      framework_ref.source_tree = 'SDKROOT'
      new_widget_target.frameworks_build_phases.add_file_reference(framework_ref)
  end

  foundation_file_reference = target_project.files.find { |file| file.display_name == 'Foundation.framework' }
  new_widget_target.frameworks_build_phase.remove_file_reference(foundation_file_reference)

  # Add a new shell script build phase
  script_phase = new_widget_target.new_shell_script_build_phase('Bundle React Native code and images')

  # Set the shell script content
  script_phase.shell_script = <<~SCRIPT
    #!/bin/sh
    set -e

    WITH_ENVIRONMENT="../node_modules/react-native/scripts/xcode/with-environment.sh"
    REACT_NATIVE_XCODE="../node_modules/rct-widget-extension/scripts/react-native-xcode-widget.sh"
    
    ENTRY_FILE="Widget.js" /bin/sh -c "$WITH_ENVIRONMENT $REACT_NATIVE_XCODE"    
  SCRIPT

  # Find or create the 'Resources' group within the target
  resources_group = new_widget_target.resources_build_phase || new_widget_target.new_resources_build_phase(nil)

  assets_ref = widget_group.new_reference("Assets.xcassets")

  # Add the Assets.xcassets folder to the target's resources
  assets_file_reference = resources_group.add_file_reference(assets_ref)

  widget_description = widget_details['description']
  widget_name = widget_details['name']

  destination_path = File.join(group_path, "#{new_widget_target_name}.swift")
  template_widget_content = File.read(destination_path)
  template_widget_content = template_widget_content.gsub('My Widget', widget_name)
  template_widget_content = template_widget_content.gsub('This is an example widget.', widget_description)

  # Write the modified content back to the file
  File.write(destination_path, template_widget_content)

  # Save the target project with the new Widget Extension target
  target_project.save

  puts "New Widget Extension target '#{new_widget_target_name}' added to the target project."
end