COLOR_GREEN = "\e[32m"
COLOR_YELLOW = "\e[33m"
COLOR_RED = "\e[31m"
COLOR_RESET = "\e[0m"

def info(text)
  puts "#{text}"
end

def success(text)
  puts "#{COLOR_GREEN}#{text}#{COLOR_RESET}"
end

def warn(text)
  puts "#{COLOR_YELLOW}#{text}#{COLOR_RESET}"
end

def error(text)
  puts "#{COLOR_RED}#{text}#{COLOR_RESET}"
end

def update_conversions(isLocalEnv)
  conversions_path = "node_modules/react-native/ReactCommon/react/renderer/attributedstring/conversions.h"

  if isLocalEnv
    conversions_path = "./example/node_modules/react-native/ReactCommon/react/renderer/attributedstring/conversions.h"
  end

  conversions_content = File.read(conversions_path)
  if_def_android_search_string = "#ifdef ANDROID";
  end_if_search_string = "#endif";
  should_update_conversions = !conversions_content.include?("//#{if_def_android_search_string}") && !conversions_content.include?("//#{end_if_search_string}")

  if should_update_conversions
    modified_content = conversions_content.gsub(if_def_android_search_string, "//#{if_def_android_search_string}")
    modified_content = modified_content.gsub(end_if_search_string, "//#{end_if_search_string}")
    
    # Write the modified content back to the conversions.h
    File.write(conversions_path, modified_content)
  end
end

def update_graphics_conversions(isLocalEnv)
  graphics_conversions_path = "node_modules/react-native/ReactCommon/react/renderer/core/graphicsConversions.h"

  if isLocalEnv
    graphics_conversions_path = "./example/node_modules/react-native/ReactCommon/react/renderer/core/graphicsConversions.h"
  end
  
  graphics_conversions_content = File.read(graphics_conversions_path)
  if_def_android_search_string = "#ifdef ANDROID";
  end_if_search_string = "#endif";
  should_update_graphics_conversions = !graphics_conversions_content.include?("//#{if_def_android_search_string}") && !graphics_conversions_content.include?("//#{end_if_search_string}")
  
  if should_update_graphics_conversions
    modified_content = graphics_conversions_content.gsub(if_def_android_search_string, "//#{if_def_android_search_string}")
    modified_content = modified_content.gsub(end_if_search_string, "//#{end_if_search_string}")
    
    # Write the modified content back to the graphicsConversions.h
    File.write(graphics_conversions_path, modified_content)
  end
end

def update_podfile(isLocalEnv, widget_target_name)
  # Read the contents of the Podfile into a string
  podfile_path = 'ios/Podfile'

  if isLocalEnv
    podfile_path = './example/ios/Podfile'
  end

  podfile_content = File.read(podfile_path)

  # The string to search for post_install
  post_install_search_string = "post_install do |installer|"

  target_lines = <<-ADD_LINES
  target '#{widget_target_name}' do
    inherit! :complete
    # Pods for widget
  end
  ADD_LINES

  # The lines to add above the search string
  deps_lines = <<-ADD_LINES
    pod 'ReactCommon-Samples', :path => "../node_modules/react-native/ReactCommon/react/nativemodule/samples"
    pod 'React-Fabric/components/rncore', :path => "../node_modules/react-native/ReactCommon"
  ADD_LINES

  # The string to search for xcode_workaround
  xcode_workaround_search_string = "__apply_Xcode_12_5_M1_post_install_workaround(installer)"

  # The lines to add above the search string
  app_extension_lines = <<-ADD_LINES
    target_names_to_update = ['FlipperKit', 'React-RCTLinking']
    installer.pods_project.targets.each do |target|
      if target_names_to_update.include?(target.name)
        target.build_configurations.each do |config|
          config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
        end
      end
    end
    ADD_LINES

  # Check if the target exists in the Podfile
  should_update_podfile_with_target = !podfile_content.include?(target_lines) && !isLocalEnv

  if should_update_podfile_with_target
    # Insert the lines above the post_install_search_string
    modified_podfile_content = podfile_content.gsub(post_install_search_string, "#{target_lines}\n#{post_install_search_string}")

    # Write the modified content back to the Podfile
    File.write(podfile_path, modified_podfile_content)

    success("Widget Target added in Podfile successfully!\n")
  end

  should_update_podfile_with_required_code = !modified_podfile_content.include?(deps_lines) && !modified_podfile_content.include?(app_extension_lines)

  # Check if the post_install_search_string and xcode_workaround_search_string exists in the Podfile
  if should_update_podfile_with_required_code
    # Insert the lines above the post_install_search_string
    modified_podfile_content = modified_podfile_content.gsub(post_install_search_string, "\n#{deps_lines}\n#{post_install_search_string}")

    # Insert the lines below the xcode_workaround_search_string
    modified_podfile_content = modified_podfile_content.gsub(xcode_workaround_search_string, "#{xcode_workaround_search_string}\n\n#{app_extension_lines}")

    # Write the modified content back to the Podfile
    File.write(podfile_path, modified_podfile_content)
    success("Podfile updated successfully!\n")
  end
end
