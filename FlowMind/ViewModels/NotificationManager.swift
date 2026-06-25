import SwiftUI
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isAuthorized = false

    init() {
        checkStatus()
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func scheduleNotification(for task: DailyTask, minutesBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🐔 Coop Flow Reminder"
        content.body = "\(task.routineIcon) \(task.routineName) is due in \(minutesBefore) minutes"
        content.sound = .default
        content.badge = 1

        let calendar = Calendar.current
        let components = task.scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return }
        var dc = calendar.dateComponents([.year, .month, .day], from: task.scheduledDate)
        dc.hour = components[0]
        dc.minute = components[1]
        guard let fireDate = calendar.date(from: dc) else { return }
        let triggerDate = fireDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        guard triggerDate > Date() else { return }

        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleAll(tasks: [DailyTask], minutesBefore: Int) {
        cancelAll()
        for task in tasks where task.status == .pending {
            scheduleNotification(for: task, minutesBefore: minutesBefore)
        }
    }
}
