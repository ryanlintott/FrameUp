//
//  VMasonry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/**
 A FrameUp `FULayout` that arranges views into a set number of rows by adding each view to the shortest row.
 
 A maximum width must be provided. `WidthReader` can be used to get the value and is especially helpful when inside a `ScrollView`.
 
 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
 
 Example:
 ```swift
 WidthReader { width in
     VMasonry(columns: 3, maxWidth: width) {
         ForEach(["Hello", "World", "More Text"], id: \.self) { item in
             Text(item.value)
         }
     }
 }
 ```
 */
public struct VMasonry: FULayout {
    typealias Column = FULayoutColumn
    
    public let alignment: FUAlignment
    public let columns: Int
    public let columnWidth: CGFloat
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    
    public var maxItemWidth: CGFloat? { columnWidth }
    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    /// Creates a FrameUp layout that arranges views columns, adding views to the shortest column.
    /// - Parameters:
    ///   - alignment: Used to align columns vertically relative to each other. Default is top.
    ///   - columns: Number of columns to place views in.
    ///   - maxWidth: Maximum width containing all columns (can be obtained through a `WidthReader`).
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUAlignment = .top,
        columns: Int,
        maxWidth: CGFloat,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingHorizontalJustification()
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
        self.columnWidth = (maxWidth - (self.horizontalSpacing * CGFloat(self.columns - 1))) / CGFloat(self.columns)
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var columns: [Column] = (0..<columns).map { _ in
            Column(alignment: alignment, minSpacing: verticalSpacing)
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
        
        columns.justifyIfNecessary()
        let alignmentHeight = columns.maxMinColumnHeight
        
        for column in columns {
            column
                .contentOffsets(columnXOffset: currentXOffset, alignmentHeight: alignmentHeight)
                .forEach { result.update(with: $0) }
            currentXOffset += columnWidth + horizontalSpacing
        }
        
        return result
    }
}
