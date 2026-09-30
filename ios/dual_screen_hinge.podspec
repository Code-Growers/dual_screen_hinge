require 'open3'

Pod::Spec.new do |s|
  s.name             = 'dual_screen_hinge'
  s.version          = '0.2.1'
  s.summary          = 'iPhone Duo-first foldable display APIs for Flutter.'
  s.description      = <<-DESC
Bridges public Android and iOS foldable display APIs to Flutter.
                       DESC
  s.homepage         = 'https://github.com/Code-Growers/dual_screen_hinge'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Code Growers' => 'opensource@codegrowers.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'dual_screen_hinge/Sources/dual_screen_hinge/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Xcode/SDK version numbers do not guarantee that these APIs are present.
  # Inspect the public UIKit declarations for each SDK independently.
  xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_SWIFT_FLAGS' => '$(inherited)'
  }
  %w[iphoneos iphonesimulator].each do |sdk|
    sdk_path, status = Open3.capture2('xcrun', '--sdk', sdk, '--show-sdk-path')
    next unless status.success?

    framework = File.join(sdk_path.strip, 'System/Library/Frameworks/UIKit.framework')
    declarations = Dir.glob(File.join(framework, '{Headers,Modules}/**/*.{h,swiftinterface}'))
      .map { |path| File.read(path) }.join("\n")
    flags = ['$(inherited)']
    if declarations.match?(/(?:@interface|\bclass)\s+UIHingeInteraction\b/)
      flags << '-DDUAL_SCREEN_HINGE_IOS27'
    end
    if declarations.match?(/\bfunc\s+reservedRegions\s*\(|\breservedRegions(?:With\w*)?\s*:/)
      flags << '-DDUAL_SCREEN_HINGE_IOS271'
    end
    xcconfig["OTHER_SWIFT_FLAGS[sdk=#{sdk}*]"] = flags.join(' ')
  end
  s.pod_target_xcconfig = xcconfig
  s.swift_version = '5.9'
  s.resource_bundles = {'dual_screen_hinge_privacy' => ['dual_screen_hinge/Sources/dual_screen_hinge/PrivacyInfo.xcprivacy']}
end
