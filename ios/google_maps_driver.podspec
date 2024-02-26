#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_maps_driver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'google_maps_driver'
  s.version          = '0.0.1'
  s.summary          = 'A Google Maps Driver Flutter plugin.'
  s.description      = <<-DESC
A Google Maps Driver Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GoogleRidesharingDriver'
  s.dependency 'google_maps_navigation'
  s.platform = :ios, '14.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.xcconfig = {
    'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) /usr/lib/swift',
  }
end