//
//  WidthReader.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-10.
//

import SwiftUI

struct WidthKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WidthReader<Content: View>: View {
    let alignment: HorizontalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var width: CGFloat = 0
    
    init(alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
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
