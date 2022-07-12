//
//  HStackLayoutStyle.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-06-01.
//

import SwiftUI

public struct HStackLayoutStyle: LayoutStyle {
    public let id = UUID()
    public let alignment: Alignment
    public let fixedSize: Axis.Set = .horizontal
    public var itemAlignment: Alignment { alignment }
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public init(
        alignment: VerticalAlignment? = nil,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: .leading, vertical: alignment ?? .top)
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }

    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
            currentPoint.x += spacing + min(size.value.width, maxItemWidth ?? .infinity)
        }

        return result
    }
}
