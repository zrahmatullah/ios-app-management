import Foundation
import UserNotifications

public final class NotificationService {
    public static let shared = NotificationService()
    
    private init() {}
    
    /// Requests local notification permission
    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("[NotificationService] Authorization error: \(error)")
            return false
        }
    }
    
    /// Schedules a reminder for an event
    public func scheduleEventReminder(id: String, title: String, date: Date, minutesBefore: Int = 15) {
        let triggerDate = date.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Pengingat Jadwal: \(title)"
        content.body = "Akan dimulai dalam \(minutesBefore) menit."
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "event-\(id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Schedules daily evening reminder to log journal and expenses
    public func scheduleDailyReviewReminder(hour: Int = 20, minute: Int = 30) {
        let content = UNMutableNotificationContent()
        content.title = "Waktunya Refleksi Harian ✨"
        content.body = "Catat pengeluaran dan suasana hatimu hari ini di Lumina."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "lumina-daily-review", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cancels scheduled reminder
    public func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event-\(id)"])
    }
}
