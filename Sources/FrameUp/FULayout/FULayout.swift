//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

public protocol FULayout: Identifiable {
    var fuLayoutName: String { get }
    
    var id: UUID { get }
    /// Alignment of view containing all subviews.
    var alignment: Alignment { get }
    /// Alignment of subviews. Does not support custom alignments.
    var itemAlignment: Alignment { get }
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
    /// Returns a bounds rect containing all views.
    /// - Parameters:
    ///   - positions: Position of the top left corner of each view.
    ///   - sizes: Size of each view.
    /// - Returns: A bounds rect containing all views.
    func rect(contentOffsets: [Int: CGPoint], sizes: [Int: CGSize]) -> CGRect {
        var minX: CGFloat = 0
        var minY: CGFloat = 0
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        let _ = sizes.forEach { size in
            guard let offset = contentOffsets[size.key] else {
                return
            }
            var x = offset.x
            var y = offset.y
            #warning("Add support for custom alignments")
            switch alignment.horizontal {
            case .center:
                x -= size.value.width / 2
            case .trailing:
                x += size.value.width / 2
            default:
                break
            }
            switch alignment.vertical {
            case .center:
                y -= size.value.height / 2
            case .bottom:
                y += size.value.height / 2
            default:
                break
            }
            minX = min(x, minX)
            minY = min(y, minY)
            maxX = max(x + size.value.width, maxX)
            maxY = max(y + size.value.height, maxY)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
//    func rect(contentOffsets: [Int: CGPoint], sizes: [Int: CGSize]) -> CGRect {
//        let rects: [CGRect] = sizes.compactMap { size in
//            guard let offset = contentOffsets[size.key] else {
//                return nil
//            }
//            var x = offset.x
//            var y = offset.y
//            #warning("Handle right-to-left")
//            switch itemAlignment.horizontal {
//            case .leading:
//                break
//            case .center:
//                x -= size.value.width / 2
//            case .trailing:
//                x -= size.value.width
//            default:
//                break
//            }
//            switch itemAlignment.vertical {
//            case .top:
//                break
//            case .center:
//                y -= size.value.height / 2
//            case .bottom:
//                y -= size.value.height
//            default:
//                break
//            }
//            return CGRect(x: x, y: y, width: size.value.width, height: size.value.height)
//        }
//
//        return rects.dropFirst().reduce(into: rects.first ?? .zero) { partialResult, rect in
//            let minX = min(partialResult.minX, rect.minX)
//            let minY = min(partialResult.minY, rect.minY)
//            let maxX = max(partialResult.maxX, rect.maxX)
//            let maxY = max(partialResult.maxY, rect.maxY)
//            partialResult = CGRect(
//                x: minX,
//                y: minY,
//                width: maxX - minX,
//                height: maxY - minY
//            )
//        }
//    }
}

