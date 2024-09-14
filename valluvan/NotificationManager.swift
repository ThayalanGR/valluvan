import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func scheduleRandomKuralNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleNotification()
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Thirukkural"
        
        let randomKuralId = Int.random(in: 1...1330)
        if let kural = DatabaseManager.shared.getKuralById(randomKuralId, language: "English") {
            content.body = "\(kural.content)\n\nTap to read more..."
            content.userInfo = ["kuralId": randomKuralId]
        } else {
            content.body = "Discover today's wisdom from Thirukkural"
        }
        
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // Set the hour you want the notification to be sent (e.g., 9 AM)
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyKural", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}