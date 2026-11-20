import Foundation
import AppIntents

#if canImport(AppIntents)
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct ToggleHabitIntent: AppIntent {
    public static var title: LocalizedStringResource = "Centang Habit Lumina"
    public static var description = IntentDescription("Tandai penyelesaian kebiasaan harian langsung dari widget.")
    
    @Parameter(title: "ID Habit")
    public var habitId: String
    
    public init() {}
    
    public init(habitId: String) {
        self.habitId = habitId
    }
    
    public func perform() async throws -> some IntentResult {
        WidgetDataBridge.toggleHabit(id: habitId)
        return .result()
    }
}
#endif
