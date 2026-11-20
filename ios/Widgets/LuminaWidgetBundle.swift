import WidgetKit
import SwiftUI

// Configured as widget bundle for Widget Extension
public struct LuminaWidgetBundle: WidgetBundle {
    public init() {}
    
    public var body: some Widget {
        LuminaBalanceWidget()
        LuminaHabitWidget()
        LuminaSavingsWidget()
    }
}
