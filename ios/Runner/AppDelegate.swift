import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Set up notification center delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound, .provisional]
      ) { granted, error in
        if granted {
          print("✅ Notification permission granted")
        } else if let error = error {
          print("❌ Notification permission error: \(error)")
        } else {
          print("❌ Notification permission denied")
        }
      }
    } else {
      let settings = UIUserNotificationSettings(
        types: [.alert, .badge, .sound],
        categories: nil
      )
      application.registerUserNotificationSettings(settings)
    }
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Handle Notification in Foreground
  
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification banner even when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }
  
  // MARK: - Handle Notification Tap
  
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped with payload: \(userInfo)")
    
    // Handle notification tap here
    // You can route to specific screens based on the payload
    
    completionHandler()
  }
  
  // MARK: - Handle Remote Notification Registration
  
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ Successfully registered for remote notifications")
    // Pass device token to Firebase Messaging
    // This is handled by FirebaseMessaging plugin automatically
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error)")
  }
  
  // MARK: - Handle Remote Notification (Background)
  
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📱 Received remote notification: \(userInfo)")
    completionHandler(.newData)
  }
}