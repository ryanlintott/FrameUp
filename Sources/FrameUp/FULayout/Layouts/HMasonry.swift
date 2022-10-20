//
//  HMasonry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/**
 A FrameUp layout that arranges views into rows, adding views to the shortest row.
 
 A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
 
 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
 
 Example:
 ```swift
 HeightReader { height in
    HMasonry(columns: 3, maxHeight: height) {
        ForEach(["Hello", "World", "More Text"], id: \.self) { item in
            Text(item.value)
                .padding(12)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(12)
        }
    }
 }
 ```
 */
public struct HMasonry: FULayout {
    typealias Row = FULayoutRow
    
    public let alignment: FUHorizontalAlignment
    public let rows: Int
    public let rowHeight: CGFloat
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public var maxItemHeight: CGFloat? { rowHeight }
    public let maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    /// Creates a FrameUp layout that arranges views into rows, adding views to the shortest row.
    /// - Parameters:
    ///   - alignment: Used to align rows horizontally relative to each other. Default is leading.
    ///   - rows: Number of rows to place views in.
    ///   - maxHeight: Maximum height containing all rows (can be obtained through a `HeightReader`).
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUHorizontalAlignment = .leading,
        rows: Int,
        maxHeight: CGFloat,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.rows = max(1, rows)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.rowHeight = (maxHeight - (self.horizontalSpacing * CGFloat(self.rows - 1))) / CGFloat(self.rows)
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var rows: [Row] = (0..<rows).map { _ in
            Row(alignment: .init(horizontal: alignment, vertical: .top), spacing: verticalSpacing, height: rowHeight)
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
