import SwiftUI

// MARK: - Cross-platform view helpers
//
// The app targets iOS/iPadOS but is written so the same SwiftUI code compiles
// and runs on macOS (and other Apple platforms). A handful of modifiers only
// exist on iOS, so these wrappers apply them conditionally and become no-ops
// elsewhere instead of failing to compile.

extension View {

    /// Shows the decimal number pad on iOS/iPadOS; no-op on platforms without a software keyboard.
    @ViewBuilder
    func decimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Shows the number pad on iOS/iPadOS; no-op on platforms without a software keyboard.
    @ViewBuilder
    func numberKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
        #else
        self
        #endif
    }

    /// Uses the inline navigation title style on iOS/iPadOS; no-op elsewhere.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: - Adaptive colors

extension Color {

    /// A subtle card fill that adapts to each platform's system palette.
    static var cardFill: Color {
        #if os(iOS)
        Color(.systemGray6)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.15)
        #endif
    }
}

// The shared `PrimaryButtonStyle` and the rest of the design system live in Theme.swift.

// MARK: - Full-screen cover

extension View {
    /// Presents a full-screen cover on iOS/iPadOS; falls back to a sheet on
    /// platforms where `fullScreenCover` is unavailable (e.g. macOS).
    @ViewBuilder
    func fullCover<C: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> C) -> some View {
        #if os(iOS)
        fullScreenCover(isPresented: isPresented, content: content)
        #else
        sheet(isPresented: isPresented, content: content)
        #endif
    }
}

// MARK: - Keyboard helpers

#if os(iOS)
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
#endif

extension View {
    /// Adds a "Done" button above the keyboard so number pads (which have no
    /// return key) can always be dismissed to reveal what's underneath.
    @ViewBuilder
    func keyboardDoneButton() -> some View {
        #if os(iOS)
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { hideKeyboard() }
                    .fontWeight(.bold)
            }
        }
        #else
        self
        #endif
    }
}
