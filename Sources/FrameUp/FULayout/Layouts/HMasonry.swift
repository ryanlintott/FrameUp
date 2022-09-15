//
//  HMasonry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout that arranges views into rows, adding views to the shortest row.
///
/// A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
///
/// A FrameUp layout is not a view but it has two functions to make a view. `.forEach()` that works like `ForEach` and `._view { }` that works more like `VStack` or similar.
///
/// Example:
///
///     HeightReader { height in
///         HMasonry(columns: 3, maxHeight: height) {
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
public struct HMasonry: FULayout {
    typealias Row = FULayoutRow
    
    public let alignment: Alignment
    public let rows: Int
    public let rowHeight: CGFloat
    public let maxItemHeight: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public let maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    /// Creates a FrameUp layout that arranges views into rows, adding views to the shortest row.
    /// - Parameters:
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is leading.
    ///   - rows: Number of rows to place views in.
    ///   - maxHeight: Maximum height containing all rows (can be obtained through a `HeightReader`).
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: Alignment = .leading,
        rows: Int,
        maxHeight: CGFloat,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.rows = max(1, rows)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.maxItemHeight = (maxHeight - (self.horizontalSpacing * CGFloat(self.rows - 1))) / CGFloat(self.rows)
        self.rowHeight = maxItemHeight ?? maxHeight
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var rows: [Row] = (0..<rows).map { _ in
            Row(alignment: alignment, spacing: verticalSpacing, height: rowHeight)
        }
        
        for size in sizes.sortedByKey() {
            // Get the shortest column
            if let row = rows
                .enumerated()
                .min(by: { $0.1.rowSize.width < $1.1.rowSize.width }) {
                rows[row.0].append(size)
            }
        }
        
        var currentYOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        for row in rows {
            row
                .contentOffsets(rowYOffset: currentYOffset)
                .forEach { result.update(with: $0) }
            currentYOffset += row.rowSize.height + verticalSpacing
        }
        
        return result
    }
}
