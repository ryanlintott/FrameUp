//
//  FUViewThatFits.swift
//  
//
//  Created by Ryan Lintott on 2022-10-31.
//

import SwiftUI

public struct FUViewThatFits: FULayout {
    public var maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    public let fixedSize: Axis.Set
    
    public init(maxWidth: CGFloat) {
        self.maxItemWidth = maxWidth
        self.maxItemHeight = nil
        self.fixedSize = .vertical
    }
    
    public init(maxHeight: CGFloat) {
        self.maxItemWidth = nil
        self.maxItemHeight = maxHeight
        self.fixedSize = .horizontal
    }
    
    public init(maxWidth: CGFloat, maxHeight: CGFloat) {
        self.maxItemWidth = maxWidth
        self.maxItemHeight = maxHeight
        self.fixedSize = []
    }
    
    public init(maxSize: CGSize) {
        self = .init(maxWidth: maxSize.width, maxHeight: maxSize.height)
    }
    
    public func fittingSize(in sizes: [Int: CGSize]) -> (key: Int, value: CGSize)? {
        let sortedSizes = sizes.sortedByKey()
        
        let size = sortedSizes
            .first { _, value in
                (fixedSize.contains(.vertical) || value.height <= maxItemHeight ?? .infinity)
                &&
                (fixedSize.contains(.horizontal) || value.width <= maxItemWidth ?? .infinity)
            }
        
        return size ?? sortedSizes.last
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        guard let key = fittingSize(in: sizes)?.key else { return [:] }
        return [key: .zero]
    }
}
