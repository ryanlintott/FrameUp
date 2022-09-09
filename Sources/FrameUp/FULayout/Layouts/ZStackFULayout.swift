//
//  ZStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct ZStackFULayout: FULayout {
    public let alignment: Alignment
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    
    public var itemAlignment: Alignment { alignment }
    public let fixedSize: Axis.Set = []
    
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
