//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct VFlowLayupView<Content: View>: View {
    @ViewBuilder
    let alignment: Alignment
    let start: Alignment
    let maxWidth: CGFloat
    let itemAlignment: Alignment
    let maxItemWidth: CGFloat?
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: () -> Content
    
    public init(
        alignment: Alignment? = nil,
        start: Alignment? = nil,
        maxWidth: CGFloat,
        itemAlignment: Alignment? = nil,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        content: @escaping () -> Content
    ) {
        self.alignment = alignment ?? .topLeading
        self.start = start ?? .topLeading
        self.maxWidth = maxWidth
        self.itemAlignment = itemAlignment ?? .topLeading
        self.maxItemWidth = min(maxWidth, maxItemWidth ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.content = content
    }
    
    var layup: VFlowLayup {
        VFlowLayup(alignment: alignment, start: start, maxWidth: maxWidth, itemAlignment: itemAlignment, maxItemWidth: maxItemWidth, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing)
    }
    
    public var body: some View {
        LayupView(layup: layup, content: content)
    }
    
}

struct VFlowLayup: Layup {
    let id = UUID()
    let alignment: Alignment
    let start: Alignment
    let maxWidth: CGFloat
    let itemAlignment: Alignment
    let maxItemWidth: CGFloat?
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    let maxItemHeight: CGFloat? = nil
    let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment? = nil,
        start: Alignment? = nil,
        maxWidth: CGFloat,
        itemAlignment: Alignment? = nil,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment ?? .topLeading
        self.start = start ?? .topLeading
        self.maxWidth = maxWidth
        self.itemAlignment = itemAlignment ?? .topLeading
        self.maxItemWidth = min(maxWidth, maxItemWidth ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var rowHeight: CGFloat = .zero
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero,
               currentPoint.x + size.value.width > maxWidth {
                currentPoint.x = .zero
                currentPoint.y += rowHeight + verticalSpacing
                rowHeight = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.x += size.value.width + horizontalSpacing
            rowHeight = max(rowHeight, size.value.height)
        }
        
        return result
    }
}
