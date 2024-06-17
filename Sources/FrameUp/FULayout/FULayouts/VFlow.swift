//
//  VFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/**
 A FrameUp `FULayout` that arranges views in vertical columns flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed columns evenly.

 Each column width will be determined by the widest element.

 A maximum height must be provided. `HeightReader` can be used to get the value and is especially helpful when inside a `ScrollView`.

 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`

 Example:
 ```swift
 HeightReader { height in
     VFlow(maxHeight: height) {
         ForEach(["Hello", "World", "More Text"], id: \.self) { item in
             Text(item.value)
         }
     }
 }
 ```
 */
public struct VFlow: FULayout, Sendable {
    typealias Column = FULayoutColumn
    
    public let alignment: FUAlignment
    public let maxHeight: CGFloat
    public let maxItemHeight: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemWidth: CGFloat? = nil
    public let fixedSize: Axis.Set = .horizontal
    
    /// Creates a FrameUp layout that arranges views in a column, adding columns when needed.
    /// - Parameters:
    ///   - alignment: Used to align views horizontally in their columns and align columns vertically relative to each other. Default is top leading.
    ///   - maxHeight: Maximum height for a column (can be obtained through a `HeightReader`).
    ///   - maxItemHeight: Maximum height for each child view default is the maximum column height.
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUAlignment = .topLeading,
        maxHeight: CGFloat,
        maxItemHeight: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingHorizontalJustification()
        self.maxHeight = maxHeight
        self.maxItemHeight = min(maxHeight, maxItemHeight ?? .infinity)
        self.horizontalSpacing = horizontalSpacing ?? 10
        self.verticalSpacing = verticalSpacing ?? 10
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var columns: [Column] = sizes
            .sortedByKey()
            .reduce(into: [Column]()) { partialResult, size in
                guard partialResult.isEmpty ||
                   !partialResult[partialResult.endIndex - 1].append(size) else {
                    return
                }
                partialResult.append(Column(alignment: alignment, minSpacing: verticalSpacing, firstSize: size, maxHeight: maxHeight))
            }
        
        var currentXOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        columns.justifyIfNecessary(height: maxHeight, skipLast: true)
        let alignmentHeight = columns.maxMinColumnHeight
        
        for column in columns {
            column
                .contentOffsets(columnXOffset: currentXOffset, alignmentHeight: alignmentHeight)
                .forEach { result.update(with: $0) }
            
            currentXOffset += column.columnSize.width + horizontalSpacing
        }
        
        return result
    }
}
