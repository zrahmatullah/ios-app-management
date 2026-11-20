import WidgetKit
import SwiftUI

@main
public struct LuminaWidgetBundle: WidgetBundle {
    public init() {}
    
    public var body: some Widget {
        LuminaBalanceWidget()
        LuminaHabitWidget()
        LuminaSavingsWidget()
    }
}
