import CoreGraphics

/// Cadence's spacing scale — a 4-pt grid. Every gap and inset *between* UI elements pulls a named
/// step from here instead of an ad-hoc literal, so the app's layout rhythm comes from one system
/// rather than per-view guesses (same idea as a design-token / Tailwind spacing scale).
///
/// Deliberately NOT in this scale: component-intrinsic geometry — fixed `frame` sizes, corner
/// radii, glyph/icon font sizes, and the small insets used to position glyphs *inside* a drawn
/// element (badge/dot overlays). Those are a separate sizing concern; snapping a tight badge inset
/// to a 4-pt step would distort fine components. They stay as literals until a sizing scale exists.
enum Space {
    /// 4 pt — tight pairings, e.g. a label stacked above its value.
    static let xs: CGFloat = 4
    /// 8 pt
    static let sm: CGFloat = 8
    /// 12 pt
    static let md: CGFloat = 12
    /// 16 pt — the default container edge inset.
    static let lg: CGFloat = 16
    /// 24 pt — spacing between major sections.
    static let xl: CGFloat = 24
}
