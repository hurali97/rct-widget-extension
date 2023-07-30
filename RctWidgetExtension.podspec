require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
folly_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1'
folly_compiler_flags = folly_flags + ' ' + '-Wno-comma -Wno-shorten-64-to-32'
boost_compiler_flags = '-Wno-documentation'

Pod::Spec.new do |s|
  s.name         = "RctWidgetExtension"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "14.0" }
  s.source       = { :git => "https://github.com/hurali97/rct-widget-extension.git", :tag => "#{s.version}" }

  s.swift_version        = '5.2'
  s.source_files         = 'ios/**/*.{m,mm,h,cpp,swift}'
  s.preserve_paths       = 'ios/**/*.{m,mm,h,cpp,swift}'
  s.private_header_files = [
    'ios/{ComponentDescriptors,Mounting,Scheduler,Shims,Surface}/**',
    'ios/Utils/RSUIConversions.h'
  ]
  s.compiler_flags         = folly_compiler_flags + ' ' + boost_compiler_flags
  s.pod_target_xcconfig  = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => [
      "$(PODS_ROOT)/DoubleConversion",
      "$(PODS_ROOT)/RCT-Folly",
      "$(PODS_ROOT)/Headers/Public/React-Fabric",
      "$(PODS_ROOT)/Headers/Public/React-RCTFabric",
      "$(PODS_ROOT)/Headers/Private/React-Core",
      "$(PODS_ROOT)/Headers/Public/React-graphics",
      "$(PODS_ROOT)/Headers/Public/React-jsi",
      "$(PODS_ROOT)/Headers/Public/Yoga",
      "$(PODS_ROOT)/Headers/Public/React-cxxreact",
      "$(PODS_ROOT)/Headers/Public/React-debug",
      "$(PODS_ROOT)/Headers/Public/ReactCommon",
      "$(PODS_ROOT)/Headers/Public/React-callinvoker",
      "$(PODS_ROOT)/Headers/Public/React-runtimeexecutor",
      "$(PODS_ROOT)/Headers/Public/React-runtimescheduler",
      "$(PODS_ROOT)/Headers/Public/React-NativeModulesApple",
      "$(PODS_ROOT)/Headers/Public/ReactCommon-Samples",
      "$(PODS_ROOT)/Headers/Public/React-hermes",
      "$(PODS_ROOT)/Headers/Public/React-jsiexecutor",
      "$(PODS_ROOT)/Headers/Public/glog",
      "$(PODS_ROOT)/boost-for-react-native",
      "$(PODS_ROOT)/boost",
      "$(PODS_ROOT)/Headers/Public/React-utils",
      "$(PODS_ROOT)/hermes-engine/destroot/include",
    ],
    "OTHER_CFLAGS" => "$(inherited) -DRN_FABRIC_ENABLED" + " " + folly_flags,
    "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
  }
end
