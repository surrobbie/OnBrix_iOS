# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'OnBrix_iOS' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase/Analytics', '9.3.0'
  pod 'Firebase/Messaging', '9.3.0'
  pod 'RealmSwift'
  pod ‘FileBrowser’
pod 'FacebookSDK' 
pod 'FacebookSDK/LoginKit' 
pod 'FacebookSDK/ShareKit' 
pod 'FacebookSDK/PlacesKit' 
pod 'FBSDKMessengerShareKit' 

  # pod 'Fabric', '~> 1.10.2'
  # pod 'Crashlytics', '~> 3.13.4'

  # Pods for OnBrix_iOS
 

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.1'
        end
    end
end
