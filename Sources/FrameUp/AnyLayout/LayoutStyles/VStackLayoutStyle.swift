//
//  VStackLayoutStyle.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-06-01.
//

import SwiftUI

public struct VStackLayoutStyle: LayoutStyle {    
    public let id = UUID()
    public let alignment: Alignment
    public let fixedSize: Axis.Set = .vertical
    public var itemAlignment: Alignment { alignment }
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public init(
        alignment: HorizontalAlignment? = nil,
        spacing: CGFloat? = nil,
        maxWidth: CGFloat,
        maxItemHeight: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: alignment ?? .leading, vertical: .top)
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxItemHeight
        self.maxItemWidth = maxWidth
    }

    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
            currentPoint.y += spacing + min(size.value.height, maxItemHeight ?? .infinity)
        }

        return result
    }
}
