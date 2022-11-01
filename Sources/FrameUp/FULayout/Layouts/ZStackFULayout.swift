//
//  ZStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `ZStackLayout`. Useful when you want to toggle between different FrameUp layouts.
public struct ZStackFULayout: FULayout {
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
    ///   - spacing: Minimum horizontal spacing between views. Default is 10
    ///   - maxHeight: Maximum height (can be obtained through a `HeightReader`).
    ///   - maxItemWidth: Maximum width for each child view. Default is infinity.
    public init(
        alignment: FUAlignment? = nil,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) {
        self.alignment = alignment ?? .center
        self.maxWidth = maxWidth
        self.maxHeight = maxHeight
    }
    
    public func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        var result = [Int: CGPoint]()
        
        for size in sizes.sortedByKey() {
            let xOffset: CGFloat
            switch alignment.horizontal {
            case .leading:
                xOffset = .zero
            case .center:
                xOffset = -size.value.width / 2
            case .trailing:
                xOffset = -size.value.width
            }
            let yOffset: CGFloat
            switch alignment.vertical {
            case .top:
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

@available(iOS 16, macOS 13, *)
extension ZStackFULayout: Layout { }
