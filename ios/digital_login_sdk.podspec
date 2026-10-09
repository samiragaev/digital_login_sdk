Pod::Spec.new do |s|
  s.name             = 'digital_login_sdk'
  s.version          = '0.2.1'
  s.summary          = 'Flutter SDK for Azerbaijan DigitalLogin.'
  s.description      = <<-DESC
Runs the DigitalLogin authorization in ASWebAuthenticationSession and also
accepts redirects that arrive from another app, such as mygov.
                       DESC
  s.homepage         = 'https://github.com/samiragaev/digital_login_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Samir Aghayev' => 'samiragazad6@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'digital_login_sdk/Sources/digital_login_sdk/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
  s.resource_bundles = { 'digital_login_sdk_privacy' => ['digital_login_sdk/Sources/digital_login_sdk/PrivacyInfo.xcprivacy'] }
end
