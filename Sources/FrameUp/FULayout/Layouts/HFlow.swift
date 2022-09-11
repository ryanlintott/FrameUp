//
//  HFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout that arranges views in a row, adding rows when needed.
///
/// Each row height will be determined by the tallest element. The overall frame size will fit to the size of the laid out content.
///
/// A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
///
/// A FrameUp layout is not a view but it works like a view by using `callAsFunction`. There is also an alternative view function `.forEach()` that works like `ForEach`
///
/// Example:
///
///     HeightReader { height in
///         HFlow(maxHeight: height) {
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
public struct HFlow: FULayout {
    typealias Row = FULayoutRow
    
    public let alignment: Alignment
    public let maxWidth: CGFloat
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    /// Creates a FrameUp layout that arranges views in a row, adding rows when needed.
    /// - Parameters:
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is top leading.
    ///   - maxWidth: Maximum width for a row (can be obtained through a `WidthReader`).
    ///   - maxItemWidth: Maximum width for each child view default is the maximum row width.
    ///   - horizontalSpacing: Minimum horizontal spacing between views in a row.
    ///   - verticalSpacing: Vertical spacing between rows.
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
