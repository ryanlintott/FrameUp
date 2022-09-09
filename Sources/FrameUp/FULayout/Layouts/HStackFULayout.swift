//
//  HStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct HStackFULayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: VerticalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .horizontal
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var row = FULayoutRow(alignment: Alignment(horizontal: .leading, vertical: alignment), spacing: spacing, height: maxItemHeight ?? .infinity)
        
        sizes.forEach { row.append($0) }
        
        return row.contentOffsets(rowYOffset: 0)
    }
}
