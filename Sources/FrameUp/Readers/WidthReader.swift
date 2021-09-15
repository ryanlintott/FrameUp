//
//  WidthReader.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-10.
//

import SwiftUI

public struct WidthKey: PreferenceKey {
    public typealias Value = CGFloat
    public static let defaultValue: CGFloat = .zero
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct WidthReader<Content: View>: View {
    let alignment: HorizontalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var width: CGFloat = 0
    
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
