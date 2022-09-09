//
//  VFlowFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct VFlowFULayout: FULayout {
    typealias Row = FULayoutRow
    
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let maxWidth: CGFloat
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment = .topLeading,
        maxWidth: CGFloat,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.maxWidth = maxWidth
        self.maxItemWidth = min(maxWidth, maxItemWidth ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        let rows: [Row] = sizes
            .sortedByKey()
            .reduce(into: [Row]()) { partialResult, size in
                guard partialResult.isEmpty ||
                   !partialResult[partialResult.endIndex - 1].append(size, maxWidth: maxWidth) else {
                    return
                }
                partialResult.append(Row(alignment: alignment, spacing: horizontalSpacing, firstSize: size))
            }
        
        let maxRowWidth = rows.map(\.rowSize.width).reduce(into: 0.0) { $0 = max($0, $1) }
        
        var currentYOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        for row in rows {
            for offset in row.contentOffsets(rowYOffset: currentYOffset) {
                result.update(with: offset)
            }
            currentYOffset += row.rowSize.height + verticalSpacing
        }
        
        return result
    }
}
