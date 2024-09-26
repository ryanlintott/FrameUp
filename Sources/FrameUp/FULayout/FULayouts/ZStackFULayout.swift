//
//  ZStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `ZStackLayout`. Useful when you want to toggle between different FrameUp layouts.
@available(iOS, introduced: 14, deprecated: 16, message: "ZStackFULayout can be replaced with SwiftUI ZStackLayout")
@available(macOS, introduced: 11, deprecated: 13, message: "ZStackFULayout can be replaced with SwiftUI ZStackLayout")
@available(watchOS, introduced: 7, deprecated: 9, message: "ZStackFULayout can be replaced with SwiftUI ZStackLayout")
@available(tvOS, introduced: 14, deprecated: 16, message: "ZStackFULayout can be replaced with SwiftUI ZStackLayout")
@available(visionOS, introduced: 1, deprecated: 1, message: "ZStackFULayout can be replaced with SwiftUI ZStackLayout")
public struct ZStackFULayout: FULayout, Sendable {
    public let alignment: FUAlignment
    public let maxWidth: CGFloat
    public let maxHeight: CGFloat
    
    public var maxItemWidth: CGFloat? { maxWidth }
    public var maxItemHeight: CGFloat? { maxHeight }
    public var itemAlignment: FUAlignment { alignment }
    public let fixedSize: Axis.Set = []
    
    /// Creates a FrameUp layout version of `ZStackLayout`.
    /// - Parameters:
    ///   - alignment: Alignment for elements.
    ///   - maxWidth: Maximum width.
    ///   - maxHeight: Maximum height.
    public init(
        alignment: FUAlignment? = nil,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) {
        self.alignment = alignment?.replacingVerticalJustification().replacingHorizontalJustification() ?? .center
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        var result = [Int: CGPoint]()
        
        for size in sizes.sortedByKey() {
            let xOffset: CGFloat
            switch alignment.horizontal {
            case .leading, .justified:
                xOffset = .zero
            case .center:
                xOffset = -size.value.width / 2
            case .trailing:
                xOffset = -size.value.width
            }
            let yOffset: CGFloat
            switch alignment.vertical {
            case .top, .justified:
                yOffset = .zero
            case .center:
                yOffset = -size.value.height / 2
            case .bottom:
                yOffset = -size.value.height
            }
            let offset = CGPoint(x: xOffset, y: yOffset)
            
            result.updateValue(offset, forKey: size.key)
        }

        return result
    }
}
