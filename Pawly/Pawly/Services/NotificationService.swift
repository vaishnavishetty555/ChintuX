import Foundation
import UserNotifications

/// PRD §6.3 — Local notification scheduling with rich actions (Mark Done / Snooze 1h).
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    static let categoryReminder = "PAWLY_REMINDER"

    static let actionMarkDone = "PAWLY_ACTION_DONE"
    static let actionSnooze1h = "PAWLY_ACTION_SNOOZE_1H"

    static func registerCategories() {
        let done = UNNotificationAction(
            identifier: actionMarkDone,
            title: "Mark Done",
            options: [.foreground]  // opens app for confirmation + SwiftData update
        )
        let snooze = UNNotificationAction(
            identifier: actionSnooze1h,
            title: "Snooze 1 hour",
            options: []
        )
        let cat = UNNotificationCategory(
            identifier: categoryReminder,
            actions: [done, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([cat])
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Schedule a single local notification for a `ReminderInstance.id` at `fireDate`.
    static func schedule(
        reminderInstanceID: UUID,
        reminderID: UUID,
        petName: String,
        title: String,
        body: String,
        fireDate: Date,
        critical: Bool = false
    ) {
        guard fireDate > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = critical ? "⚠️ Missed reminder for \(petName)" : title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryReminder
        content.userInfo = [
            "instanceID": reminderInstanceID.uuidString,
            "reminderID": reminderID.uuidString,
            "critical": critical
        ]
        let interval = max(1, fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let req = UNNotificationRequest(
            identifier: reminderInstanceID.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    /// Schedule a second "critical" nudge 4 hours after the first for overdue
    /// medications (PRD §6.3).
    static func scheduleCriticalReNotify(
        reminderInstanceID: UUID,
        reminderID: UUID,
        petName: String,
        originalFire: Date
    ) {
        let fire = originalFire.addingTimeInterval(60 * 60 * 4)
        schedule(
            reminderInstanceID: reminderInstanceID,
            reminderID: reminderID,
            petName: petName,
            title: "Still not marked done",
            body: "\(petName) may have missed a dose. Tap to review.",
            fireDate: fire,
            critical: true
        )
    }

    static func cancel(reminderInstanceID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [reminderInstanceID.uuidString]
        )
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // V1: the app handles state changes when opened via the foreground
        // "Mark Done" action. Snooze action is scheduled here.
        let userInfo = response.notification.request.content.userInfo
        guard
            let instanceIDStr = userInfo["instanceID"] as? String,
            let instanceID = UUID(uuidString: instanceIDStr),
            let reminderIDStr = userInfo["reminderID"] as? String,
            let reminderID = UUID(uuidString: reminderIDStr)
        else { return }

        switch response.actionIdentifier {
        case Self.actionSnooze1h:
            let snoozeUntil = Date().addingTimeInterval(60 * 60)
            Self.schedule(
                reminderInstanceID: instanceID,
                reminderID: reminderID,
                petName: (userInfo["petName"] as? String) ?? "your pet",
                title: response.notification.request.content.title,
                body: response.notification.request.content.body,
                fireDate: snoozeUntil
            )
        default:
            break  // opening the app is handled by SwiftUI scene delegates
        }
    }
}
