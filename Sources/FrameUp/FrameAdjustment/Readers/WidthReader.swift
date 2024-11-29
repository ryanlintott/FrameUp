//
//  WidthReader.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-10.
//

import SwiftUI

/// Preference key used to pass the width of a child view up the hierarchy.
///
/// Used by `WidthReader`.
///
/// Only one key is necessary and works even in nested situations because the value is captured and used inside reader view. Nested views will replace the value before reading it so the correct value should always be sent through.
public struct WidthKey: PreferenceKey {
    public typealias Value = CGFloat
    public static let defaultValue: CGFloat = .zero
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// A view that takes the available width and provides this measurement to its content. Unlike `GeometryReader` this view will not take up all the available height and will instead fit the height of the content.
///
/// Useful inside vertical scroll views where you want to measure the width without specifying a frame height.
public struct WidthReader<Content: View>: View {
    let alignment: HorizontalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var width: CGFloat = 0
    
    /// Creates a view takes the available width and provides this measurement to its content.
    /// - Parameters:
    ///   - alignment: Horizontal alignment
    ///   - content: any `View`
    public init(alignment: HorizontalAlignment = .center, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
       
    @ViewBuilder
    public var elements: some View {
        Color.clear.overlay(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: WidthKey.self, value: proxy.size.width)
            }
        )
        .frame(height: 0)
        .onPreferenceChangeMainActor(WidthKey.self) { newWidth in
            if width == newWidth { return }
            width = newWidth
        }
        
        /// Only show the content if the width has been set (is not zero)
        if width > 0 {
            content(width)
        }
    }
    
    public var body: some View {
        /// This extra VStack is here because trying to apply frame modifiers to WidthReader may not work correctly without it.
        VStack {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                FittedVStack(alignment: .init(alignment) ?? .center) {
                    elements
                }
            } else {
                VStack(alignment: alignment, spacing: 0) {
                    elements
                }
            }
        }
    }
}
