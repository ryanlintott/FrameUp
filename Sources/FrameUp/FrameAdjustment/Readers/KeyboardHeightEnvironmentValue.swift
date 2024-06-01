//
//  KeyboardHeightEnvironmentValue.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-02-01.
//

import SwiftUI


private struct KeyboardHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    /// Height of software keyboard when visible
    var keyboardHeight: CGFloat {
        get { self[KeyboardHeightEnvironmentKey.self] }
        set { self[KeyboardHeightEnvironmentKey.self] = newValue }
    }
}

public extension Animation {
    /// An approximation of Apple's keyboard animation
    ///
    /// source: https://forums.developer.apple.com/forums/thread/48088
    static var keyboard: Self {
        .interpolatingSpring(mass: 3, stiffness: 1000, damping: 500, initialVelocity: 0)
    }
}

#if os(iOS)
struct KeyboardHeightEnvironmentValue: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .environment(\.keyboardHeight, keyboardHeight)
            .animation(.keyboard, value: keyboardHeight)
            .background(
                GeometryReader { keyboardProxy in
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: keyboardProxy.safeAreaInsets.bottom - proxy.safeAreaInsets.bottom) { newValue in
                                DispatchQueue.main.async {
                                    if keyboardHeight != newValue {
                                        keyboardHeight = newValue
                                    }
                                }
                            }
                    }
                    .ignoresSafeArea(.keyboard)
                }
            )
    }
}
#endif

public extension View {
    /// Adds an environment value for software keyboard height when visible
    ///
    /// Must be applied on a view taller than the keyboard that touches the bottom edge of the safe area.
    /// Access keyboard height in any child view with
    /// @Environment(\.keyboardHeight) var keyboardHeight
    func keyboardHeightEnvironmentValue() -> some View {
        #if os(iOS)
        modifier(KeyboardHeightEnvironmentValue())
        #else
        environment(\.keyboardHeight, 0)
        #endif
    }
}

#Preview {
    VStack {
        TextField("Example", text: .constant(""))
    }
    .keyboardHeightEnvironmentValue()
}
