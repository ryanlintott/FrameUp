//
//  VMasonryFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout that arranges views columns, adding views to the shortest column.
///
/// A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).
///
/// A FrameUp layout is not a view but it has two functions to make a view. `.forEach()` that works like `ForEach` and `._view { }` that works more like `VStack` or similar.
///
/// Example:
///
///     WidthReader { width in
///         VMasonry(columns: 3, maxWidth: width) {
///             ForEach(["Hello", "World", "More Text"], id: \.self) { item in
///                 Text(item.value)
///                     .padding(12)
///                     .foregroundColor(.white)
///                     .background(Color.blue)
///                     .cornerRadius(12)
///                     .clipped()
///             }
///         }
///     }
///
public struct VMasonry: FULayout {
    typealias Column = FULayoutColumn
    
    public let alignment: Alignment
    public let columns: Int
    public let columnWidth: CGFloat
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    /// Creates a FrameUp layout that arranges views columns, adding views to the shortest column.
    /// - Parameters:
    ///   - alignment: Used to align views horizontally in their columns and align columns vertically relative to each other. Default is top.
    ///   - columns: Number of columns to place views in.
    ///   - maxWidth: Maximum width containing all columns (can be obtained through a `WidthReader`).
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: Alignment = .top,
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
            if let column = columns
                .enumerated()
                .min(by: { $0.1.columnSize.height < $1.1.columnSize.height }) {
                columns[column.0].append(size)
            }
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
