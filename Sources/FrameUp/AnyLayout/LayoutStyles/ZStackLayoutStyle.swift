//
//  ZStackLayoutStyle.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-06-01.
//

import SwiftUI

public struct ZStackLayoutStyle: LayoutStyle {
    public let id = UUID()
    public let alignment: Alignment
    public var itemAlignment: Alignment { alignment }
    public let fixedSize: Axis.Set = []
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    
    public init(
        alignment: Alignment? = nil,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) {
        self.alignment = alignment ?? .topLeading
        self.maxItemWidth = maxWidth
        self.maxItemHeight = maxHeight
    }
    
    public func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        let currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
        }

        return result
    }
}
