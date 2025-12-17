#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_driver_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'google_driver_flutter'
  s.version          = '0.0.1'
  s.summary          = 'A Google Maps Driver Flutter plugin.'
  s.description      = <<-DESC
A Google Maps Driver Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'google_driver_flutter/Sources/google_driver_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'GoogleRidesharingDriver', '~> 10.0.0'
  s.dependency 'google_navigation_flutter'
  s.platform = :ios, '16.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'google_driver_flutter_privacy_info' => ['google_driver_flutter/Sources/google_driver_flutter/PrivacyInfo.xcprivacy']}
end