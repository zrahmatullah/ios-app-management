import Foundation
import SwiftUI

@MainActor
public final class GoalsViewModel: ObservableObject {
    @Published public var goals: [Goal] = []
    @Published public var habits: [Habit] = []
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    public init() {}
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let gTask: [Goal] = GoBridgeService.shared.dispatch(action: "list_goals")
            async let hTask: [Habit] = GoBridgeService.shared.dispatch(action: "list_habits")
            let (g, h) = try await (gTask, hTask)
            self.goals = g
            self.habits = h
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    public func toggleTask(taskId: String) async {
        do {
            let _: Bool = try await GoBridgeService.shared.dispatch(
                action: "toggle_goal_task",
                payload: ["task_id": taskId]
            )
            await loadData()
            HapticManager.impact(.light)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func addTask(goalId: String, title: String) async {
        do {
            let payload: [String: Any] = [
                "goal_id": goalId,
                "title": title,
                "is_completed": false,
                "order_index": 0
            ]
            let _: GoalTask = try await GoBridgeService.shared.dispatch(action: "save_goal_task", payload: payload)
            await loadData()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func toggleHabit(habitId: String) async {
        do {
            let _: [String: Bool] = try await GoBridgeService.shared.dispatch(
                action: "toggle_habit_today",
                payload: ["habit_id": habitId]
            )
            await loadData()
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func createGoal(title: String, category: String, priority: String, deadline: Date) async -> Bool {
        do {
            let payload: [String: Any] = [
                "title": title,
                "category": category,
                "priority": priority,
                "deadline": ISO8601DateFormatter().string(from: deadline),
                "status": "ACTIVE",
                "progress": 0.0
            ]
            let _: Goal = try await GoBridgeService.shared.dispatch(action: "save_goal", payload: payload)
            await loadData()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func createHabit(title: String, icon: String, color: String) async -> Bool {
        do {
            let payload: [String: Any] = [
                "title": title,
                "frequency": "DAILY",
                "icon": icon,
                "color": color
            ]
            let _: Habit = try await GoBridgeService.shared.dispatch(action: "save_habit", payload: payload)
            await loadData()
            HapticManager.notification(.success)
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
}
