//
//  FUViewThatFits.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-10-31.
//

import SwiftUI

/**
 An `FULayout` that presents the first view that fits the provided maxWidth, maxHeight, or both depending on which parameters are used.
 
 As this view cannot measure the available space the maxWidth and/or maxHeight parameters need to be passed in using a `GeometryReader`, `WidthReader`, or `HeightReader`.
 
 Example:
 ```swift
 WidthReader { width in
     FUViewThatFits(maxWidth: width) {
         Group {
             Text("This layout will pick the first view that fits the available width.")
             Text("Maybe this?")
             Text("OK!")
         }
         .fixedSize(horizontal: true, vertical: false)
     }
 }
 ```
 
 (`.fixedSize` needs to be used in this example or the first view will automatically fit by truncating the text)
 */
public struct FUViewThatFits: FULayout {
    public let maxItemWidth: CGFloat?
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
