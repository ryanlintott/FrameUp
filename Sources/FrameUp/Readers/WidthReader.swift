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

/// Provides the available width while fitting to the height of the content.
///
/// Useful inside vertical scroll views where you want to get the width without specifying a frame height.
public struct WidthReader<Content: View>: View {
    let alignment: HorizontalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var width: CGFloat = 0
    
    /// Creates a view that fills the available width while fitting to the height of the content.
    /// - Parameters:
    ///   - alignment: Horizontal alignment
    ///   - content: any `View`
    public init(alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: WidthKey.self, value: proxy.size.width)
            }
            .frame(height: 0)
            .onPreferenceChange(WidthKey.self) { width in
                self.width = width
            }

            content(width)
        }
    }
}
