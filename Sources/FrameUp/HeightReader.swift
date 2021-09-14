//
//  HeightReader.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

struct HeightKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HeightReader<Content: View>: View {
    let alignment: VerticalAlignment
    @ViewBuilder let content: (CGFloat) -> Content
    
    @State private var height: CGFloat = 0
    
    init(alignment: VerticalAlignment = .top, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.alignment = alignment
        self.content = content
    }
    
    var body: some View {
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
