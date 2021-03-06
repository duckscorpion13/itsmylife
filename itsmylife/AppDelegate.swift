//
//  AppDelegate.swift
//  itsmylife
//
//  Created by 楊健麟 on 2017/1/7.
//  Copyright © 2017年 楊健麟. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

import Fabric
import Crashlytics
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate
{
    let lm = CLLocationManager()
    var window: UIWindow?
    var bgTask: UIBackgroundTaskIdentifier!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        lm.requestWhenInUseAuthorization()
        
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted == false {
                print("使用者未授權")
            }
        }
        
        application.registerForRemoteNotifications()
        
//        center.setNotificationCategories(setCategories())
        center.delegate = self
        
        // 推播通知
//        self.sendNotification()
        application.applicationIconBadgeNumber=0
        
        Fabric.with([Crashlytics.self])
        
        FirebaseApp.configure()
        
        return true
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        updateMap()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        updateMap()
    }
    
    func updateMap(){
        var vc = self.window?.rootViewController
        while(vc?.presentedViewController != nil){
            vc = vc?.presentedViewController
        }
        if let vc = vc{
            if vc is UINavigationController{
                let topVc = (vc as! UINavigationController).topViewController
                if let mapVc = topVc as? MapVC{
                    mapVc.fetchAll()
                }
            }
            else if vc is UITabBarController{
                let selVc = (vc as! UITabBarController).selectedViewController
                if selVc is UINavigationController{
                    let topVc = (selVc as! UINavigationController).topViewController
                    if let mapVc = topVc as? MapVC{
                        mapVc.fetchAll()
                    }
                }
            }
            else{
                if let mapVc = vc as? MapVC{
                    mapVc.fetchAll()
                }
            }
        }
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let str = NSData(data:deviceToken)
        print(str)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
//    func sendNotification() {
//        let content = UNMutableNotificationContent()
//        content.categoryIdentifier = "c1"
//        content.title = "推播測試"
//        content.body = "Hello"
//        content.badge = 3
//        content.sound = UNNotificationSound.default()
//        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//        let request = UNNotificationRequest(identifier: "myid", content: content, trigger: trigger)
//        
//        let center = UNUserNotificationCenter.current()
//        center.add(request)
//    }
//    
//    func setCategories() -> Set<UNNotificationCategory> {
//        var set = Set<UNNotificationCategory>()
//        
//        let a1 = UNNotificationAction(
//            identifier: "a1",
//            title: "按鈕1",
//            options: []
//        )
//        let a2 = UNNotificationAction(
//            identifier: "a2",
//            title: "按鈕2",
//            options: [.foreground]
//        )
//        let a3 = UNNotificationAction(
//            identifier: "Stop",
//            title: "Stop",
//            options: [.destructive, .authenticationRequired]
//        )
//        let a4 = UNTextInputNotificationAction(
//            identifier: "a4",
//            title: "回覆",
//            options: []
//        )
//        
//        let c1 = UNNotificationCategory(
//            identifier: "c1",
//            actions: [a1, a2, a3, a4],
//            intentIdentifiers: [],
//            options: []
//        )
//        
//        set.insert(c1)
//        
//        return set
//    }
//    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping(UNNotificationPresentationOptions) -> Void) {
//        
//        // 透過 notification.request.identifier 得知是哪個推播
//        
//        // 若前景也要顯示訊息框，執行以下程式碼即可
//        completionHandler([.alert])
//    }
    
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        //        let r = response as! UNTextInputNotificationResponse
//        //
//        //        print(r.notification.request.content.categoryIdentifier) // 例如 "c1"
//        //        print(r.actionIdentifier) // 例如 "a4"
//        //        print(r.userText) // 例如 "hi"
//        
//        print(response.notification.request.content.categoryIdentifier)
//        print(response.actionIdentifier)
//        
//        if(response.actionIdentifier=="Stop"){
//            self.timer?.invalidate()
//        }
//        else{
//            if(self.timer==nil){
//                self.timer=Timer.scheduledTimer(withTimeInterval: 1800.0, repeats: true){ _ in self.sendNotification()}
//            }
//        }
//        
//        if response.actionIdentifier == "a4"{
//            if let r = response as? UNTextInputNotificationResponse{
//                print(r.userText)
//            }
//        }
//    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("進入背景狀態")
        bgTask = application.beginBackgroundTask(expirationHandler: {
            print("借用時間已用完")
            application.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskInvalid
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        updateMap()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

