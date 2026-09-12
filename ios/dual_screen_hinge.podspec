Pod::Spec.new do |s|
  s.name             = 'dual_screen_hinge'
  s.version          = '0.2.0'
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

  xcode_version = Gem::Version.new(`xcodebuild -version`.lines.first.to_s.split.last || '0')
  swift_flags = ['$(inherited)']
  swift_flags << '-DDUAL_SCREEN_HINGE_IOS27' if xcode_version >= Gem::Version.new('27.0')
  swift_flags << '-DDUAL_SCREEN_HINGE_IOS271' if xcode_version >= Gem::Version.new('27.1')

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_SWIFT_FLAGS' => swift_flags.join(' ')
  }
  s.swift_version = '5.9'
  s.resource_bundles = {'dual_screen_hinge_privacy' => ['dual_screen_hinge/Sources/dual_screen_hinge/PrivacyInfo.xcprivacy']}
end
