//
//  VFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/**
 A FrameUp layout that arranges views in a column, adding columns when needed.

 Each column width will be determined by the widest element. The overall frame size will fit to the size of the laid out content.

 A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).

 A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`

 Example:
 ```swift
 WidthReader { width in
     VFlow(maxWidth: width) {
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
public struct VFlow: FULayout {
    typealias Column = FULayoutColumn
    
    public let alignment: Alignment
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
        alignment: Alignment? = nil,
        maxHeight: CGFloat,
        maxItemHeight: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment ?? .topLeading
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
