//
//  VStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct VStackFULayout: FULayout {
    public let id = UUID()
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        maxWidth: CGFloat,
        maxItemHeight: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxItemHeight
        self.maxItemWidth = maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var column = FULayoutColumn(alignment: Alignment(horizontal: alignment, vertical: .top), spacing: spacing, width: maxItemWidth ?? .infinity)
        
        sizes.forEach { column.append($0) }
        
        return column.contentOffsets(columnXOffset: 0)
    }
}
