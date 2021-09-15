//
//  ScrollViewWithPosition.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-07-01.
//

import SwiftUI

public struct TopOffsetKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct BottomOffsetKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct ScrollViewWithPosition<Content: View>: View {
    @Binding public var topOffset: CGFloat?
    @Binding public var bottomOffset: CGFloat?
    public let showsIndicators: Bool
    
    public let content: () -> Content
    
    public init(topOffset: Binding<CGFloat?> = .constant(nil), bottomOffset: Binding<CGFloat?> = .constant(nil), showsIndicators: Bool, content: @escaping () -> Content) {
        self._topOffset = topOffset
        self._bottomOffset = bottomOffset
        self.showsIndicators = showsIndicators
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { proxy in
            Color.clear.overlay(
                ScrollView(.vertical, showsIndicators: showsIndicators) {
                    content()
                        .anchorPreference(key: TopOffsetKey.self, value: .top) {
                            proxy[$0].y
                        }
                        .anchorPreference(key: BottomOffsetKey.self, value: .bottom) {
                            proxy[$0].y - proxy.size.height
                        }
                }
            )
        }
        .onPreferenceChange(TopOffsetKey.self) { value in
            topOffset = value
        }
        .onPreferenceChange(BottomOffsetKey.self) { value in
            bottomOffset = value
        }
    }
}
