//
//  HFlowFULayout.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct HFlowFULayout: FULayout {
    typealias Column = FULayoutColumn
    
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let maxHeight: CGFloat
    public let maxItemHeight: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    public init(
        alignment: Alignment = .topLeading,
        maxHeight: CGFloat,
        maxItemHeight: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.maxHeight = maxHeight
        self.maxItemHeight = min(maxHeight, maxItemHeight ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        let columns: [Column] = sizes
            .sortedByKey()
            .reduce(into: [Column]()) { partialResult, size in
                guard partialResult.isEmpty ||
                   !partialResult[partialResult.endIndex - 1].append(size, maxHeight: maxHeight) else {
                    return
                }
                partialResult.append(Column(alignment: alignment, spacing: verticalSpacing, firstSize: size))
            }
        
        var currentXOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        for column in columns {
            column
                .contentOffsets(columnXOffset: currentXOffset)
                .forEach { result.update(with: $0) }
            
            currentXOffset += column.columnSize.width + horizontalSpacing
        }
        
        return result
    }
}
