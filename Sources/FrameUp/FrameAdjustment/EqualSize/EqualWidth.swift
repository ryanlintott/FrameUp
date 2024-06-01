//
//  EqualWidth.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-03-08.
//

import SwiftUI

private struct EqualWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: Binding<CGFloat?> = .constant(nil)
}

public extension EnvironmentValues {
    /// A shared binding to a width value that can be used to make views have equal width
    var equalWidth: Binding<CGFloat?> {
        get { self[EqualWidthEnvironmentKey.self] }
        set { self[EqualWidthEnvironmentKey.self] = newValue }
    }
}

struct EqualWidthKey: PreferenceKey {
    typealias Value = CGFloat?
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let nextValue = nextValue() {
            value = max(value ?? .zero, nextValue)
        } else {
            value = nil
        }
    }
}

private struct EqualWidthViewModifier: ViewModifier {
    @Environment(\.equalWidth) @Binding var equalWidth
    
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: true, vertical: false)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: EqualWidthKey.self, value: proxy.size.width)
                }
                    .onPreferenceChange(EqualWidthKey.self) {
                        equalWidth = $0
                    }
            )
            .frame(maxWidth: equalWidth)
    }
}

private struct EqualWidthContainerViewModifier: ViewModifier {
    @State private var equalWidth: CGFloat? = nil
    
    func body(content: Content) -> some View {
        content
            .environment(\.equalWidth, $equalWidth)
    }
}

public extension View {
    /// Adds an action to perform when parent view size value changes.
    /// - Parameter action: The action to perform when the size changes. The action closure passes the new value as its parameter.
    /// - Returns: A view with an invisible background `GeometryReader` that detects and triggers an action when the size changes.
    func equalWidthPreferred() -> some View {
        modifier(EqualWidthViewModifier())
    }
    
    func equalWidthContainer() -> some View {
        modifier(EqualWidthContainerViewModifier())
    }
}

#Preview {
    HStack {
        Button { } label: {
            Text("More Information")
                .equalWidthPreferred()
        }
        Spacer()
        
        Button { } label: {
            Text("Cancel")
                .equalWidthPreferred()
        }
        
        Spacer()
        
        Button { } label: {
            Text("OK")
                .equalWidthPreferred()
        }
    }
    .equalWidthContainer()
    .frame(maxWidth: 400)
    .padding()
}
