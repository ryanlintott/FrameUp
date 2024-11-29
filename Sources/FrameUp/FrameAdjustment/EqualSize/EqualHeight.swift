//
//  EqualHeight.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-03-08.
//

import SwiftUI

private struct EqualHeightEnvironmentKey: EnvironmentKey {
    static let defaultValue: Binding<CGFloat?> = .constant(nil)
}

public extension EnvironmentValues {
    /// A shared binding to a height value that can be used to make views have equal height
    var equalHeight: Binding<CGFloat?> {
        get { self[EqualHeightEnvironmentKey.self] }
        set { self[EqualHeightEnvironmentKey.self] = newValue }
    }
}

struct EqualHeightKey: PreferenceKey {
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

struct EqualHeightViewModifier: ViewModifier {
    @Environment(\.equalHeight) @Binding var equalHeight
    
    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: EqualHeightKey.self, value: proxy.size.height)
                }
                    .onPreferenceChangeMainActor(EqualHeightKey.self) {
                        equalHeight = $0
                    }
            )
            .frame(maxHeight: equalHeight)
    }
}

struct EqualHeightContainerViewModifier: ViewModifier {
    @State private var equalHeight: CGFloat? = nil
    
    func body(content: Content) -> some View {
        content
            .environment(\.equalHeight, $equalHeight)
    }
}

public extension View {
    /// This view will have a height equal to the largest view with this modifier inside a view with ``SwiftUICore/View/equalHeightContainer()``. If space is limited views will shrink equally, each to a minimum fixed size that fits the content.
    func equalHeightPreferred() -> some View {
        modifier(EqualHeightViewModifier())
    }
    
    /// Views inside this view using ``SwiftUICore/View/equalHeightPreferred()`` will have a height equal to the largest view with that modifier. If space is limited these views will shrink equally, each to a minimum fixed size that fits the content.
    func equalHeightContainer() -> some View {
        modifier(EqualHeightContainerViewModifier())
    }
}

#Preview {
    HStack {
        Group {
            Text("Here's something with some text")
            
            Text("And more")
        }
        .foregroundColor(.white)
        .padding()
        .equalHeightPreferred()
        .background(
            Color.blue.cornerRadius(10)
        )
    }
    .equalHeightContainer()
    .frame(maxWidth: 200)
    .padding()
}
