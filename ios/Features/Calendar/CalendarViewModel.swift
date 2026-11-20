import Foundation
import SwiftUI

@MainActor
public final class CalendarViewModel: ObservableObject {
    @Published public var events: [CalendarEvent] = []
    @Published public var selectedDate: Date = Date()
    @Published public var dayTransactions: [Transaction] = []
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadEvents() async {
        isLoading = true
        errorMessage = nil
        do {
            let res: [CalendarEvent] = try await GoBridgeService.shared.dispatch(action: "list_events")
            self.events = res
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func createEvent(
        title: String,
        start: Date,
        end: Date,
        location: String,
        color: String,
        reminderMinutes: Int
    ) async -> Bool {
        do {
            let payload: [String: Any] = [
                "title": title,
                "start_time": ISO8601DateFormatter().string(from: start),
                "end_time": ISO8601DateFormatter().string(from: end),
                "location": location,
                "color": color,
                "recurrence": "NONE",
                "reminder_minutes": reminderMinutes,
                "is_completed": false
            ]
            let created: CalendarEvent = try await GoBridgeService.shared.dispatch(action: "save_event", payload: payload)
            
            // Schedule local notification if reminder set
            if reminderMinutes > 0 {
                _ = await NotificationService.shared.requestAuthorization()
                NotificationService.shared.scheduleEventReminder(
                    id: created.id,
                    title: created.title,
                    date: created.startTime,
                    minutesBefore: reminderMinutes
                )
            }
            
            await loadEvents()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func deleteEvent(id: String) async {
        do {
            let _: Bool = try await GoBridgeService.shared.dispatch(
                action: "delete_event",
                payload: ["id": id]
            )
            NotificationService.shared.cancelNotification(id: id)
            await loadEvents()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public var eventsForSelectedDate: [CalendarEvent] {
        events.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
    }
}
