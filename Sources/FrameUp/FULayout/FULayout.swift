//
//  FULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

/// A type that can create a FrameUp view layout.
public protocol FULayout: Equatable {
    /// Axes that will have a fixed size.
    var fixedSize: Axis.Set { get }
    /// Max width for a subview.
    var maxItemWidth: CGFloat? { get }
    /// Max height for a subview
    var maxItemHeight: CGFloat? { get }
    
    /// Returns a dictionary of offsets for each subview keyed to an integer id based on a corresponding dictionary of sizes of those subviews.
    ///
    /// These offsets are used to re-position each subview
    /// - Parameter sizes: Sizes of each subview keyed to an integer id.
    /// - Returns: A dictionary of offsets for each subview keyed to an integer id based on a corresponding dictionary of sizes of those subviews.
    func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint]
}

public extension FULayout {
    /// Creates a bounding rectangle that encloses all the subviews based on their size and offset.
    /// - Parameters:
    ///   - contentOffsets: Offsets of all subviews.
    ///   - sizes: Sizes of all subviews.
    /// - Returns: A bounding rectangle that encloses all the subviews based on their size and offset.
    func rect(contentOffsets: [Int: CGPoint], sizes: [Int: CGSize]) -> CGRect {
        let rects: [CGRect] = sizes.compactMap { size in
            guard let offset = contentOffsets[size.key] else {
                return nil
            }
            
            return CGRect(x: offset.x, y: offset.y, width: size.value.width, height: size.value.height)
        }

        return rects.dropFirst().reduce(into: rects.first ?? .zero) { partialResult, rect in
            let minX = min(partialResult.minX, rect.minX)
            let minY = min(partialResult.minY, rect.minY)
            let maxX = max(partialResult.maxX, rect.maxX)
            let maxY = max(partialResult.maxY, rect.maxY)
            partialResult = CGRect(
                x: minX,
                y: minY,
                width: maxX - minX,
                height: maxY - minY
            )
        }
    }
}

