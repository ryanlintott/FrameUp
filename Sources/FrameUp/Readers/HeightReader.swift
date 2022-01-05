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
struct HeightKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Provides the available height while fitting to the width of the content.
public struct HeightReader<Content: View>: View {
    let alignment: VerticalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var height: CGFloat = 0
    
    /// Creates a view that fills the available height while fitting to the width of the content
    /// - Parameters:
    ///   - alignment: Vertical alignment
    ///   - content: any `View`
    public init(alignment: VerticalAlignment = .top, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    public var body: some View {
        HStack(alignment: alignment, spacing: 0) {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightKey.self, value: proxy.size.height)
            }
            .frame(width: 0)
            .onPreferenceChange(HeightKey.self) { height in
                self.height = height
            }
            
            content(height)
        }
    }
}
