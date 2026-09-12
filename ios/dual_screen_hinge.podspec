Pod::Spec.new do |s|
  s.name             = 'dual_screen_hinge'
  s.version          = '0.1.0'
  s.summary          = 'Foldable display state and hinge angles for Flutter.'
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

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_SWIFT_FLAGS[sdk=iphoneos27.*]' => '$(inherited) -DDUAL_SCREEN_HINGE_IOS27',
    'OTHER_SWIFT_FLAGS[sdk=iphonesimulator27.*]' => '$(inherited) -DDUAL_SCREEN_HINGE_IOS27'
  }
  s.swift_version = '5.9'
  s.resource_bundles = {'dual_screen_hinge_privacy' => ['dual_screen_hinge/Sources/dual_screen_hinge/PrivacyInfo.xcprivacy']}
end
