//
//  AppDelegate.swift
//  OnBrix_iOS
//
//  Created by rrobbie on 2023/02/13.
//

import UIKit
import Firebase
import FBSDKCoreKit
import UserNotifications
import AudioToolbox
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    let userDefault = UserDefaults.standard
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Constants.token = fcmToken ?? ""
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.alert, .sound]])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        
        let url = userInfo["url"] as? String ?? ""
        let linkUrl = userInfo["linkUrl"] as? String ?? ""
        self.setData(data: url, key: "url")
        self.postNotification(name: .subDataPushed)
                
        completionHandler()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print(error.localizedDescription)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
        FirebaseApp.configure()
        Settings.isAutoLogAppEventsEnabled = true
        Settings.isAutoInitEnabled = true
        ApplicationDelegate.initializeSDK(nil)
        
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        
        // 푸시 알림 권한 설정 및 푸시 알림에 앱 등록
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        application.registerForRemoteNotifications()

        //쿠키데이터 삽입
        let cookiesData: Data? = UserDefaults.standard.object(forKey: "Cookies") as? Data

        if ((cookiesData?.count) != nil) {
            let cookies: [Any]? = NSKeyedUnarchiver.unarchiveObject(with: cookiesData!) as? [Any]
            
            for cookie: HTTPCookie in (cookies as? [HTTPCookie])! {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }

        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.cookieAcceptPolicy = .always

        if self.window != nil{
            let navigationController = UINavigationController(rootViewController: (self.window?.rootViewController)!)
            navigationController.isNavigationBarHidden = true
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }

        Constants.AppDelegate = self
        Constants.isPush = self.userDefault.object(forKey: "isPush") as? Bool ?? true

        registerForPushNotifications()
        
        ApplicationDelegate.shared.application(
                    application,
                    didFinishLaunchingWithOptions: launchOptions
                )
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(UIBackgroundFetchResult.newData)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

extension AppDelegate{
    
    func registerNotification(observer:Any, aSelector:Selector, name:NSNotification.Name, object:Any? = nil){
        NotificationCenter.default.addObserver(observer, selector: aSelector, name: name, object: object)
    }
    
    func removeNotification(observer:Any){
        NotificationCenter.default.removeObserver(observer)
    }
    
    func postNotification(name:NSNotification.Name, object:Any? = nil){
        NotificationCenter.default.post(name: name, object: object)
    }
    
    func setData(data:Any, key:String){
        let userDefault = UserDefaults.standard
        userDefault.set(data, forKey: key)
        userDefault.synchronize()
    }
    
    func getData(key:String) -> Any {
        let userDefault = UserDefaults.standard
        return userDefault.object(forKey: key) as Any
    }
    
    func registerForPushNotifications() {
        // 1 - UNUserNotificationCenter는 푸시 알림을 포함하여 앱의 모든 알림 관련 활동을 처리합니다.
        UNUserNotificationCenter.current()
        // 2 -알림을 표시하기 위한 승인을 요청합니다. 전달된 옵션은 앱에서 사용하려는 알림 유형을 나타냅니다. 여기에서 알림(alert), 소리(sound) 및 배지(badge)를 요청합니다.
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                // 3 - 완료 핸들러는 인증이 성공했는지 여부를 나타내는 Bool을 수신합니다. 인증 결과를 표시합니다.
                print("Permission granted: \(granted)")
                
                // 추가
                guard granted else { return }
                self.getNotificationSettings()
            }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}


