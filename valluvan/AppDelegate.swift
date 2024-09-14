import UIKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.scheduleRandomKuralNotification()
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let kuralId = response.notification.request.content.userInfo["kuralId"] as? Int {
            NotificationCenter.default.post(name: Notification.Name("OpenKuralNotification"), object: nil, userInfo: ["kuralId": kuralId])
        }
        completionHandler()
    }
}