Pod::Spec.new do |s|
  s.name             = 'linkzly_flutter_sdk'
  s.version          = '0.1.0'
  s.summary          = 'Flutter SDK for Linkzly deep linking and attribution.'
  s.description      = 'Flutter bridge for the Linkzly native iOS and Android SDKs.'
  s.homepage         = 'https://github.com/Linkzly/linkzly-flutter-sdk'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Linkzly' => 'support@linkzly.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.dependency       'LinkzlySDK', '~> 1.0'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.frameworks       = 'Foundation', 'UIKit', 'StoreKit'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0'
  }
end
