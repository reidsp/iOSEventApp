//
//  AppDelegate.swift
//  iOSEventApp
//
//  Created by Nathaniel Brown on 3/5/18.
//  Copyright © 2018 LightSys. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // Can this be moved to after a qr code is scanned?
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    // Request permission to display alerts and play sounds.
    center.requestAuthorization(options: [.alert, .sound])
    { (granted, error) in
      print("notifications authorization granted, error:", granted, error)
    }

    var refreshRateMinutes = -1
    let chosenRate = UserDefaults.standard.integer(forKey: "chosenRefreshRateMinutes")
    if chosenRate != 0 {
      refreshRateMinutes = chosenRate
    }
    else {
      let defaultRate = UserDefaults.standard.integer(forKey: "defaultRefreshRateMinutes")
      if defaultRate != 0 {
        refreshRateMinutes = defaultRate
      }
    }

    if refreshRateMinutes == -1 {
      application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }
    else {
      application.setMinimumBackgroundFetchInterval(TimeInterval(refreshRateMinutes * 60))
    }
    
    return true
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler(.alert)
  }

  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//    let loader = DataController(newPersistentContainer: persistentContainer)
//    loader.reloadNotifications { (success, errors) in
//      if success {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
          // Do not schedule notifications if not authorized.
          guard settings.authorizationStatus == .authorized else {return}
          
          let content = UNMutableNotificationContent()
          content.title = "New notification!" // TODO: Not necessarily... find a way to determine if there are actually new ones
          content.body = "What is it? Open the app and find out"
          
          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
          let request = UNNotificationRequest(identifier: "Event Notification", content: content, trigger: trigger)
          notificationCenter.add(request, withCompletionHandler: nil)
          //      if settings.alertSetting == .enabled {
          //        // Schedule an alert-only notification.
          //        self.myScheduleAlertNotification()
          //      }
          //      else {
          //        // Schedule a notification with a badge and sound.
          //        self.badgeAppAndPlaySound()
          //      }
        }
        completionHandler(.newData)
//      }
//      else {
//        let notificationCenter = UNUserNotificationCenter.current()
//        notificationCenter.getNotificationSettings { (settings) in
//          // Do not schedule notifications if not authorized.
//          guard settings.authorizationStatus == .authorized else {return}
//
//          let content = UNMutableNotificationContent()
//          content.title = "Notification fetch failed!"
//          content.body = DataController.messageForErrors(errors)
//
//          let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//          let request = UNNotificationRequest(identifier: "Event Notification", content: content, trigger: trigger)
//          notificationCenter.add(request, withCompletionHandler: nil)
//        }
//        completionHandler(.failed)
//      }
//    }
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Cancel the refresh timer (otherwise it will probably fire when the app foregrounds)
    RefreshController.cancelRefresh()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    DataController.startRefreshTimer()
  }
  
  // MARK: - Core Data stack
  
  lazy var persistentContainer: NSPersistentContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentContainer(name: "iOSEventApp")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        
        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

  // MARK: - Core Data Saving support
  // TODO: is this called by default in application will terminate (see call hierarchy)
  func saveContext() {
    let context = persistentContainer.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
  
}

