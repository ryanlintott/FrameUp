//
//  HFlowFULayout.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct HFlowFULayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let start: Alignment
    public let maxHeight: CGFloat
    public let itemAlignment: Alignment
    public let maxItemHeight: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public var maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    public init(
        alignment: VerticalAlignment? = nil,
        start: Alignment? = nil,
        maxHeight: CGFloat,
        itemAlignment: HorizontalAlignment? = nil,
        maxItemHeight: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: .leading, vertical: alignment ?? .top)
        self.start = start ?? .topLeading
        self.maxHeight = maxHeight
        self.itemAlignment = Alignment(horizontal: itemAlignment ?? .leading, vertical: .top)
        self.maxItemHeight = min(maxHeight, maxItemHeight ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var columnWidth: CGFloat = .zero
        
        for size in sizes.sortedByKey() {
            if currentPoint != .zero,
               currentPoint.y + size.value.height > maxHeight {
                currentPoint.y = .zero
                currentPoint.x += columnWidth + horizontalSpacing
                columnWidth = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.y += size.value.height + verticalSpacing
            columnWidth = max(columnWidth, size.value.width)
        }
        
        return result
    }
}
