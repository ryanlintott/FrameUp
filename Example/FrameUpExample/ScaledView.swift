//
//  ScaledView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-22.
//

import SwiftUI

public struct SizeKey: PreferenceKey {
    public typealias Value = CGSize
    public static let defaultValue: CGSize = .zero
    public static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

public struct ScaledView: ViewModifier {
    let width: CGFloat
    let height: CGFloat
    let contentMode: ContentMode?
    
    @State private var contentSize: CGSize = .zero
    
    var scaleEffect: CGPoint {
        guard contentSize != .zero else {
            return CGPoint(x: 1, y: 1)
        }
        let x = width / contentSize.width
        let y = height / contentSize.height
        
        switch contentMode {
        case .fit:
            return CGPoint(x: min(x,y), y: min(x,y))
        case .fill:
            return CGPoint(x: max(x,y), y: max(x,y))
        case nil:
            return CGPoint(x: x, y: y)
        }
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizeKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizeKey.self) { contentSize in
                self.contentSize = contentSize
            }
            .scaleEffect(x: scaleEffect.x, y: scaleEffect.y)
            .frame(width: width, height: height)
    }
}

extension View {
    func scaledToFrame(width: CGFloat, height: CGFloat, contentMode: ContentMode? = .fit) -> some View {
        self.modifier(ScaledView(width: width, height: height, contentMode: contentMode))
    }
}

struct ScaledView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello")
            .font(.largeTitle)
            .background(Color.red)
            .fixedSize()
            .scaledToFrame(width: 50, height: 50, contentMode: .fit)
            .background(Color.blue)
    }
}
