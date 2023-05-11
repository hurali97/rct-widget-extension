require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
# folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'
folly_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1'

Pod::Spec.new do |s|
  s.name         = "RctWidgetExtension"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "14.0" }
  s.source       = { :git => "https://github.com/hurali97/rct-widget-extension.git", :tag => "#{s.version}" }

  # s.source_files = "ios/**/*.{h,m,mm}"

  # s.dependency "React-Core"
  s.swift_version        = '5.2'
  s.source_files         = 'ios/**/*.{m,mm,h,cpp,swift}'
  s.preserve_paths       = 'ios/**/*.{m,mm,h,cpp,swift}'
  # s.library                = "stdc++"
  s.private_header_files = [
    'ios/{ComponentDescriptors,Mounting,Scheduler,Shims,Surface}/**',
    'ios/Utils/RSUIConversions.h'
  ]
  s.pod_target_xcconfig  = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => "\"$(PODS_TARGET_SRCROOT)/ReactCommon\" \"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/DoubleConversion\" \"$(PODS_ROOT)/React-Fabric\" \"$(PODS_ROOT)/RCT-Folly\" \"$(PODS_ROOT)/Headers/Public/React-Fabric\" \"$(PODS_ROOT)/Headers/Private/React-Core\" \"$(PODS_ROOT)/Headers/Public/React-graphics\" \"$(PODS_ROOT)/Headers/Public/React-jsi\" \"$(PODS_ROOT)/Headers/Public/Yoga\" \"$(PODS_ROOT)/Headers/Public\" \"$(PODS_ROOT)/Headers/Public/React-cxxreact\" \"$(PODS_ROOT)/Headers/Public/ReactCommon\" \"$(PODS_ROOT)/Headers/Public/React-callinvoker\" \"$(PODS_ROOT)/Headers/Public/React-runtimeexecutor\" \"$(PODS_ROOT)/Headers/Public/React-jsiexecutor\" \"$(PODS_ROOT)/Headers/Public/glog\""
  }
    s.xcconfig               = { "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost-for-react-native\" \"$(PODS_ROOT)/glog\" \"$(PODS_ROOT)/React-graphics\" \"$(PODS_ROOT)/React-Fabric\" \"$(PODS_ROOT)/RCT-Folly\" \"$(PODS_ROOT)/Headers/Public/React-Fabric\" \"$(PODS_ROOT)/Headers/Public/React-graphics\" \"$(PODS_ROOT)/Headers/Public/React-jsi\" \"$(PODS_ROOT)/Headers/Public/Yoga\" \"$(PODS_ROOT)/Headers/Public\" \"$(PODS_ROOT)/Headers/Public/React-cxxreact\" \"$(PODS_ROOT)/Headers/Public/ReactCommon\" \"$(PODS_ROOT)/Headers/Public/React-callinvoker\" \"$(PODS_ROOT)/Headers/Public/React-runtimeexecutor\" \"$(PODS_ROOT)/Headers/Public/React-jsiexecutor\" \"$(PODS_ROOT)/Headers/Public/glog\"",
                               "OTHER_CFLAGS" => "$(inherited) -DRN_FABRIC_ENABLED" + " " + folly_flags }

                              #  s.dependency "RCT-Folly"

  # Don't install the dependencies when we run `pod install` in the old architecture.
  # if ENV['RCT_NEW_ARCH_ENABLED'] == '1' then
  #   s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
  #   s.pod_target_xcconfig    = {
  #       "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
  #       "OTHER_CPLUSPLUSFLAGS" => "-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1",
  #       "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
  #   }
  #   s.dependency "React-Codegen"
  #   s.dependency "RCT-Folly"
  #   s.dependency "RCTRequired"
  #   s.dependency "RCTTypeSafety"
  #   s.dependency "ReactCommon/turbomodule/core"
  # end
end
