platform :ios, '15.0'
use_frameworks!
inhibit_all_warnings!

target 'TukTuk' do
  pod 'EasyAnimation'
  pod 'CollectionViewSlantedLayout'
  pod 'Amplitude-iOS'
  pod 'GoogleAPIClientForREST/Drive'
  pod 'GoogleSignIn'
  pod 'PopupDialog'
  pod 'SwiftyGif'
  pod 'TOPasscodeViewController'
  pod 'BiometricAuthentication'
end

# ref https://stackoverflow.com/questions/63056454/xcode-12-deployment-target-warnings-when-use-cocoapods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 9.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end
