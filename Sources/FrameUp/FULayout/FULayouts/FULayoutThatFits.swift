//
//  FULayoutThatFits.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-11-01.
//

import SwiftUI

/**
 An `FULayout` that picks the first provided layout that will fit the content in the provided maxWidth, maxHeight, or both. This is most helpful when switching between `HStackFULayout` and `VStackFULayout` as the content only needs to be provided once and will even animate when the stack changes.

 ```swift
 FULayoutThatFits(
     maxWidth: maxWidth,
     layouts: [
         HStackFULayout(maxHeight: 1000),
         VStackFULayout(maxWidth: maxWidth)
     ]
 ) {
     Color.green.frame(width: 50, height: 50)
     Color.yellow.frame(width: 50, height: 200)
     Color.blue.frame(width: 50, height: 100)
 }
 ```
 */
public struct FULayoutThatFits: FULayout {
    public let layouts: [AnyFULayout]
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    public let fixedSize: Axis.Set
    
    public init(maxWidth: CGFloat, layouts: [any FULayout]) {
        self.layouts = layouts.map(\.anyFULayout)
        self.maxItemWidth = maxWidth
        self.maxItemHeight = nil
        self.fixedSize = .vertical
    }
    
    public init(maxHeight: CGFloat, layouts: [any FULayout]) {
        self.layouts = layouts.map(\.anyFULayout)
        self.maxItemWidth = nil
        self.maxItemHeight = maxHeight
        self.fixedSize = .horizontal
    }
    
    public init(maxWidth: CGFloat, maxHeight: CGFloat, layouts: [any FULayout]) {
        self.layouts = layouts.map(\.anyFULayout)
        self.maxItemWidth = maxWidth
        self.maxItemHeight = maxHeight
        self.fixedSize = []
    }
    
    public init(maxSize: CGSize, layouts: [any FULayout]) {
        self.layouts = layouts.map(\.anyFULayout)
        self.maxItemWidth = maxSize.width
        self.maxItemHeight = maxSize.height
        self.fixedSize = []
    }
    
    public func layoutThatFits(sizes: [Int: CGSize]) -> AnyFULayout? {
        layouts.first { layout in
            let contentOffsets = layout.contentOffsets(sizes: sizes)
            let size = layout.rect(contentOffsets: contentOffsets, sizes: sizes).size
            
            return (fixedSize.contains(.vertical) || size.height <= maxItemHeight ?? .infinity)
            &&
            (fixedSize.contains(.horizontal) || size.width <= maxItemWidth ?? .infinity)
        } ?? layouts.last
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        layoutThatFits(sizes: sizes)?.contentOffsets(sizes: sizes) ?? [:]
    }
}
