require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'fileutils'

# Evaluate the real podspec while substituting only SDK discovery.
module Pod
  class Spec
    class << self
      attr_accessor :last
    end
    attr_reader :attributes

    def initialize
      @attributes = {}
      self.class.last = self
      yield self
    end

    def method_missing(name, *arguments)
      @attributes[name.to_s.delete_suffix('=')] = arguments.first
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end
end

class SDKAPIDetectionTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)
  PODSPEC = File.join(ROOT, 'ios/dual_screen_hinge.podspec')
  PACKAGE = File.join(ROOT, 'ios/dual_screen_hinge')

  def setup
    @temporary = Dir.mktmpdir('hinge-sdk-test')
    @sdks = {}
    @original_capture2 = Open3.method(:capture2)
    sdks = @sdks
    Open3.define_singleton_method(:capture2) do |*arguments|
      raise "Unexpected command: #{arguments.inspect}" unless arguments[0] == 'xcrun'
      path = sdks[arguments[2]]
      [path.to_s, Struct.new(:success?).new(!path.nil?)]
    end
  end

  def teardown
    Open3.define_singleton_method(:capture2, @original_capture2)
    FileUtils.remove_entry(@temporary)
  end

  def sdk(name, contents, extension = 'h')
    path = File.join(@temporary, name)
    directory = extension == 'h' ? 'Headers' : 'Modules/UIKit.swiftmodule'
    file = File.join(path, 'System/Library/Frameworks/UIKit.framework', directory, "API.#{extension}")
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, contents)
    @sdks[name] = path
  end

  def pod_flags
    load PODSPEC
    Pod::Spec.last.attributes.fetch('pod_target_xcconfig')
  end

  def swift_defines(sdk_path)
    # Substitute SDK discovery only; SDKROOT would also redirect the host Swift
    # compiler to the fixture, which is intentionally not a complete Apple SDK.
    manifest = File.read(File.join(PACKAGE, 'Package.swift'))
    manifest.sub!(/func selectedSDKPath\(\) -> String\? \{.*?\nfunc uiKitDeclarations/m,
                  "func selectedSDKPath() -> String? { #{sdk_path.to_json} }\n\nfunc uiKitDeclarations")
    package_path = File.join(@temporary, 'package')
    FileUtils.mkdir_p(package_path)
    File.write(File.join(package_path, 'Package.swift'), manifest)
    output, error, status = Open3.capture3(
      'swift', 'package', '--package-path', package_path, 'dump-package'
    )
    assert status.success?, error
    JSON.parse(output).fetch('targets').first.fetch('settings').map do |setting|
      setting.fetch('kind').fetch('define').fetch('_0')
    end
  end

  def test_sdk_without_apis_uses_fallback_in_both_integrations
    sdk('iphoneos', '@interface UIView : NSObject @end')
    sdk('iphonesimulator', '@interface UIView : NSObject @end')
    flags = pod_flags
    assert_equal '$(inherited)', flags.fetch('OTHER_SWIFT_FLAGS')
    %w[iphoneos iphonesimulator].each do |name|
      assert_equal '$(inherited)', flags.fetch("OTHER_SWIFT_FLAGS[sdk=#{name}*]")
    end
    assert_empty swift_defines(@sdks.fetch('iphoneos'))
  end

  def test_header_apis_enable_both_integrations
    sdk('iphoneos', <<~HEADER)
      @interface UIHingeInteraction : NSObject
      @end
      - (NSArray *)reservedRegionsWithKind:(NSInteger)kind;
      @property (nonatomic, readonly) UIVerticalBarEdge verticalBarEdge;
    HEADER
    flags = pod_flags.fetch('OTHER_SWIFT_FLAGS[sdk=iphoneos*]')
    assert_includes flags, '-DDUAL_SCREEN_HINGE_IOS27'
    assert_includes flags, '-DDUAL_SCREEN_HINGE_IOS271'
    assert_includes flags, '-DDUAL_SCREEN_HINGE_VERTICAL_BAR'
    assert_equal %w[DUAL_SCREEN_HINGE_IOS27 DUAL_SCREEN_HINGE_IOS271 DUAL_SCREEN_HINGE_VERTICAL_BAR],
                 swift_defines(@sdks.fetch('iphoneos'))
  end

  # The enum alone, without the trait property, must not enable the reader.
  def test_vertical_bar_edge_requires_the_trait_property
    sdk('iphoneos', 'typedef NS_ENUM(NSInteger, UIVerticalBarEdge) { UIVerticalBarEdgeUnspecified = 0 };')
    sdk('iphonesimulator', 'public var verticalBarEdge: UIKit.UIVerticalBarEdge { get }', 'swiftinterface')
    flags = pod_flags
    assert_equal '$(inherited)', flags.fetch('OTHER_SWIFT_FLAGS[sdk=iphoneos*]')
    assert_equal '$(inherited) -DDUAL_SCREEN_HINGE_VERTICAL_BAR', flags.fetch('OTHER_SWIFT_FLAGS[sdk=iphonesimulator*]')
    assert_empty swift_defines(@sdks.fetch('iphoneos'))
    assert_equal ['DUAL_SCREEN_HINGE_VERTICAL_BAR'], swift_defines(@sdks.fetch('iphonesimulator'))
  end

  def test_swift_interfaces_and_sdk_features_are_independent
    sdk('iphoneos', 'public class UIHingeInteraction : UIKit.UIInteraction {}', 'swiftinterface')
    sdk('iphonesimulator', 'public func reservedRegions(kind: UIKit.UIReservedRegion.Kind) -> [UIKit.UIReservedRegion]', 'swiftinterface')
    flags = pod_flags
    assert_equal '$(inherited) -DDUAL_SCREEN_HINGE_IOS27', flags.fetch('OTHER_SWIFT_FLAGS[sdk=iphoneos*]')
    assert_equal '$(inherited) -DDUAL_SCREEN_HINGE_IOS271', flags.fetch('OTHER_SWIFT_FLAGS[sdk=iphonesimulator*]')
    assert_equal ['DUAL_SCREEN_HINGE_IOS27'], swift_defines(@sdks.fetch('iphoneos'))
    assert_equal ['DUAL_SCREEN_HINGE_IOS271'], swift_defines(@sdks.fetch('iphonesimulator'))
  end

  def test_missing_sdk_does_not_enable_apis
    assert_equal '$(inherited)', pod_flags.fetch('OTHER_SWIFT_FLAGS')
    assert_empty swift_defines(File.join(@temporary, 'missing-sdk'))
  end
end
