import SwiftUI

public enum LuminaFont {
    public static func largeTitle() -> Font {
        .system(.largeTitle, design: .rounded).weight(.bold)
    }
    
    public static func title() -> Font {
        .system(.title, design: .rounded).weight(.bold)
    }
    
    public static func title2() -> Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }
    
    public static func title3() -> Font {
        .system(.title3, design: .rounded).weight(.semibold)
    }
    
    public static func headline() -> Font {
        .system(.headline, design: .rounded).weight(.semibold)
    }
    
    public static func body() -> Font {
        .system(.body, design: .rounded)
    }
    
    public static func callout() -> Font {
        .system(.callout, design: .rounded)
    }
    
    public static func subheadline() -> Font {
        .system(.subheadline, design: .rounded)
    }
    
    public static func footnote() -> Font {
        .system(.footnote, design: .rounded)
    }
    
    public static func caption() -> Font {
        .system(.caption, design: .rounded)
    }
}
