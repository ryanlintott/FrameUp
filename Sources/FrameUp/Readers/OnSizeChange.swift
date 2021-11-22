//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-11-22.
//

import SwiftUI

/// Only one key is necessary and works even in nested situations because the value is captured and used inside reader view.
/// Nested views will replace the value before reading it so the correct value should always be sent through.
public struct SizeKey: PreferenceKey {
    public typealias Value = CGSize
    public static let defaultValue: CGSize = .zero
    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

public extension View {
    func onSizeChange(perform action: @escaping (CGSize) -> Void) -> some View {
        self
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizeKey.self, perform: action)
    }
}
