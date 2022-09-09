//
//  VMasonryFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct VMasonryFULayout: FULayout {
    typealias Column = FULayoutColumn
    
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let columns: Int
    public let columnWidth: CGFloat
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment = .topLeading,
        columns: Int,
        maxWidth: CGFloat,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.maxItemWidth = (maxWidth - (self.horizontalSpacing * CGFloat(self.columns - 1))) / CGFloat(self.columns)
        self.columnWidth = maxItemWidth ?? maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var columns: [Column] = (0..<columns).map { _ in
            Column(alignment: alignment, spacing: verticalSpacing, width: columnWidth)
        }
        
        for size in sizes.sortedByKey() {
            // Get the shortest column
            if let column = columns.enumerated().min(by: {
                $0.1.columnSize.height < $1.1.columnSize.height
            }) {
                columns[column.0].append(size)
            }
        }
        
        var currentXOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        for column in columns {
            for offset in column.contentOffsets(columnXOffset: currentXOffset) {
                result.update(with: offset)
            }
            currentXOffset += column.columnSize.width + horizontalSpacing
        }
        
        return result
    }
}
