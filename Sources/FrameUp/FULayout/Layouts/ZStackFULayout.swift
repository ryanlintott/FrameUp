//
//  ZStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `ZStackLayout`. Useful when you want to animate between different FrameUp layouts.
///
/// *Only topLeading, top, topTrailing, leading, center, trailing, bottomLeading, bottom, and bottomTrailing alignments are supported*
public struct ZStackFULayout: FULayout {
    public let alignment: Alignment
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    
    public var itemAlignment: Alignment { alignment }
    public let fixedSize: Axis.Set = []
    
    /// Creates a FrameUp layout version of `ZStackLayout`.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. *Only topLeading, top, topTrailing, leading, center, trailing, bottomLeading, bottom, and bottomTrailing are supported*.
    ///   - spacing: Minimum horizontal spacing between views. Default is 10
    ///   - maxHeight: Maximum height (can be obtained through a `HeightReader`).
    ///   - maxItemWidth: Maximum width for each child view. Default is infinity.
    public init(
        alignment: Alignment? = nil,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) {
        self.alignment = alignment ?? .center
        self.maxItemWidth = maxWidth
        self.maxItemHeight = maxHeight
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
            default:
                /// Custom alignments not supported
                xOffset = .zero
            }
            let yOffset: CGFloat
            switch alignment.vertical {
            case .top:
                yOffset = .zero
            case .center:
                yOffset = -size.value.height / 2
            case .bottom:
                yOffset = -size.value.height
            default:
                /// Custom alignments not supported
                yOffset = .zero
            }
            let offset = CGPoint(x: xOffset, y: yOffset)
            
            result.updateValue(offset, forKey: size.key)
        }

        return result
    }
}

@available(iOS 16, *)
extension ZStackFULayout {
    /// SwiftUI layout using the same alignment value.
    var layout: ZStackLayout {
        ZStackLayout(alignment: alignment)
    }
}
