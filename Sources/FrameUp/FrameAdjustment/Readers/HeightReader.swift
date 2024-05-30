//
//  HeightReader.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

/// Preference key used to pass the height of a child view up the hierarchy.
///
/// Used by `HeightReader`.
///
/// Only one key is necessary and works even in nested situations because the value is captured and used inside reader view. Nested views will replace the value before reading it so the correct value should always be sent through.
public struct HeightKey: PreferenceKey {
    public typealias Value = CGFloat
    public static let defaultValue: CGFloat = .zero
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// A view that takes the available height and provides this measurement to its content. Unlike 'GeometryReader' this view will not take up all the available width and will instead fit the width of the content.
///
/// Useful inside horizontal scroll views where you want to measure the height without specifying a frame width.
@MainActor
public struct HeightReader<Content: View>: View {
    let alignment: VerticalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var height: CGFloat = 0
    
    /// Creates a view takes the available height and provides this measurement to its content.
    /// - Parameters:
    ///   - alignment: Vertical alignment
    ///   - content: any `View`
    public init(alignment: VerticalAlignment = .top, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    @MainActor
    @ViewBuilder
    public var elements: some View {
        Color.clear.overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightKey.self, value: proxy.size.height)
            }
        )
        .frame(width: 0)
        .onPreferenceChange(HeightKey.self) { newHeight in
            if height == newHeight { return }
            /// Using a task will break animation on height changes but it prevents crashes (especially on macOS when the height changes frequently.
            Task { @MainActor in
                if height == newHeight { return }
                height = newHeight
            }
        }
        
        /// Only show the content if the height has been set (is not zero)
        if height > 0 {
            content(height)
        }
    }
    
    public var body: some View {
        /// This extra HStack is here because trying to apply frame modifiers to HeightReader may not work correctly without it.
        HStack {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                FittedHStack(alignment: .init(alignment) ?? .center) {
                    elements
                }
            } else {
                HStack(alignment: alignment, spacing: 0) {
                    elements
                }
            }
        }
    }
}
