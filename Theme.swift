import SwiftUI

// MARK: - Design tokens
//
// A small, kid-friendly design system shared by every screen so the app looks
// consistent and modern, and scales cleanly from small phones to large iPads.

enum Theme {

    // Bright, friendly palette (soft enough to stay readable for young users).
    static let primary   = Color.fromHex("#3E8DFF")   // friendly blue
    static let secondary = Color.fromHex("#34C796")   // mint green
    static let accent    = Color.fromHex("#FFB020")   // sunny yellow
    static let coral      = Color.fromHex("#FF6B6B")  // playful red/coral
    static let purple    = Color.fromHex("#8E7CFF")
    static let teal      = Color.fromHex("#0FB5AE")   // investment
    static let ink       = Color.fromHex("#243B53")   // soft navy for text

    // Spacing scale.
    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat  = 12
        static let m: CGFloat  = 20
        static let l: CGFloat  = 28
        static let xl: CGFloat = 40
    }

    static let corner: CGFloat = 22

    /// Content is capped at this width so it fills large screens without becoming
    /// an over-wide, hard-to-read line length on iPad.
    static let contentMaxWidth: CGFloat = 900

    static let backgroundGradient = LinearGradient(
        colors: [Color.fromHex("#EAF4FF"), Color.fromHex("#F5EEFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// An auto-flowing grid that adds/removes columns based on available width.
    static func adaptiveColumns(minWidth: CGFloat = 150, spacing: CGFloat = Space.m) -> [GridItem] {
        [GridItem(.adaptive(minimum: minWidth), spacing: spacing)]
    }
}

// MARK: - Age band (drives how big/wordy lessons are)

enum AgeBand {
    case young    // ~2nd grade & under: big text, lots of pictures
    case mid      // ~3rd–5th grade
    case older    // ~6th grade & up: smaller text, more detail

    /// Numeric level for difficulty tracking (1=young, 2=mid, 3=older).
    var bandLevel: Int {
        switch self { case .young: return 1; case .mid: return 2; case .older: return 3 }
    }

    /// Reads birth year stored when the user first entered their age; auto-advances each year.
    static var current: AgeBand {
        let defaults = UserDefaults.standard
        let currentYear = Calendar.current.component(.year, from: Date())
        let age: Int
        if let birthYear = defaults.object(forKey: "survey_birthYear") as? Int {
            let computed = max(4, currentYear - birthYear)
            defaults.set(computed, forKey: "survey_age")   // keep display in sync
            age = computed
        } else {
            age = defaults.object(forKey: "survey_age") as? Int ?? 10
        }
        if age <= 8 { return .young }
        else if age <= 11 { return .mid }
        else { return .older }
    }

    var titleFont: Font {
        switch self {
        case .young: .largeTitle.weight(.heavy)
        case .mid:   .title.weight(.heavy)
        case .older: .title2.weight(.heavy)
        }
    }

    var bodyFont: Font {
        switch self {
        case .young: .title2
        case .mid:   .title3
        case .older: .body
        }
    }

    var emojiSize: CGFloat {
        switch self {
        case .young: 88
        case .mid:   68
        case .older: 52
        }
    }
}

// MARK: - App background

/// The full-bleed photo background for a screen. Each screen passes its own
/// image name; the image fills the screen edge-to-edge on any device.
struct AppBackground: View {
    var image: String = "background3"
    /// A light translucent scrim laid over the photo so content stays readable.
    var tint: Double = 0.35
    var body: some View {
        // Color.clear takes the proposed size and does not report a large ideal
        // size, so this background never inflates the layout it sits behind
        // (a scaledToFill image on its own would push siblings wider than the
        // screen). The photo is drawn as an overlay and clipped to fit.
        Color.clear
            .overlay(
                Image(image)
                    .resizable()
                    .scaledToFill()
            )
            .overlay(Color.white.opacity(tint))
            .clipped()
            .ignoresSafeArea()
    }
}

/// A scroll view that centers its content both horizontally and vertically on
/// any device: it caps the width (so it doesn't stretch on iPad), fills that
/// width with even side margins (so it doesn't look narrow on iPhone), and
/// keeps content vertically centered while still scrolling when it overflows.
struct CenteredScrollView<Content: View>: View {
    var maxWidth: CGFloat = Theme.contentMaxWidth
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content()
                    .frame(maxWidth: maxWidth)
                    // The content itself is made at least a full screen tall (minus
                    // margins). Screens that add `Spacer()`s between sections then
                    // spread to fill that height; screens without spacers stay
                    // comfortably centered. Taller content simply scrolls.
                    .frame(maxWidth: .infinity, minHeight: max(geo.size.height - Theme.Space.l * 2, 0))
                    .padding(.horizontal, Theme.Space.l)
                    .padding(.vertical, Theme.Space.l)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

// MARK: - Card

private struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Space.m
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Theme.ink.opacity(0.10), radius: 14, y: 8)
    }
}

extension View {
    /// Wraps content in the standard rounded, soft-shadowed card.
    func card(padding: CGFloat = Theme.Space.m) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// Centers content and caps its width so layouts stay comfortable on iPad.
    func responsiveWidth(_ maxWidth: CGFloat = Theme.contentMaxWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Section title

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Text field

enum FieldKeyboard { case standard, decimal, number }

/// A rounded, friendly text field with a built-in placeholder — replaces the
/// repeated ZStack placeholder pattern and unifies the input look everywhere.
struct KidTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: FieldKeyboard = .standard

    var body: some View {
        field
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.fromHex("#F1F5FB"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .foregroundStyle(Theme.ink)
            .tint(Theme.primary)
    }

    @ViewBuilder
    private var field: some View {
        let base = TextField(
            "",
            text: $text,
            prompt: Text(placeholder).foregroundColor(Theme.ink.opacity(0.45))
        )
        .textFieldStyle(.plain)

        switch keyboard {
        case .standard: base
        case .decimal:  base.decimalKeyboard()
        case .number:   base.numberKeyboard()
        }
    }
}

// MARK: - Buttons

/// The app's primary action button: big, rounded, and tappable for young users.
struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = Theme.primary
    var icon: String? = nil

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Theme.Space.s) {
            if let icon { Image(systemName: icon) }
            configuration.label
        }
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 54)
        .padding(.horizontal, Theme.Space.m)
        .background(
            fill.opacity(configuration.isPressed ? 0.85 : 1),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .shadow(color: fill.opacity(0.35), radius: 10, y: 6)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
