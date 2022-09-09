//
//  VFlowFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct VFlowFULayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let maxWidth: CGFloat
    public let maxItemWidth: CGFloat?
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat

    public let maxItemHeight: CGFloat? = nil
    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: Alignment = .topLeading,
        maxWidth: CGFloat,
        itemAlignment: VerticalAlignment = .top,
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
    
    struct Row {
        let spacing: CGFloat
        let alignment: Alignment
        private(set) var sizes: [Int: CGSize]
        private(set) var rowSize: CGSize
        
        init(alignment: Alignment, spacing: CGFloat, firstSize: (key: Int, value: CGSize)) {
            self.alignment = alignment
            self.spacing = spacing
            self.sizes = [firstSize.key: firstSize.value]
            self.rowSize = firstSize.value
        }
        
        mutating func append(_ element: (key: Int, value: CGSize), maxWidth: CGFloat) -> Bool {
            let newWidth = rowSize.width + element.value.width + spacing
            guard newWidth <= maxWidth else { return false }
            sizes.update(with: element)
            rowSize.width = newWidth
            rowSize.height = max(rowSize.height, element.value.height)
            return true
        }
        
        func contentOffsets(rowYOffset: CGFloat, maxRowWidth: CGFloat) -> [Int: CGPoint] {
            var currentXOffset = 0.0
            
            switch alignment.horizontal {
            case .center:
                currentXOffset -= rowSize.width / 2
            case .trailing:
                currentXOffset -= rowSize.width
            default:
                /// Custom alignments not supported
                break
            }
            
            var result = [Int: CGPoint]()

            for size in sizes.sorted(by: { $0.key < $1.key }) {
                var yOffset = rowYOffset
                switch alignment.vertical {
                case .center:
                    yOffset += (rowSize.height - size.value.height) / 2
                case .bottom:
                    yOffset += rowSize.height - size.value.height
                default:
                    /// Custom alignments not supported
                    break
                }
                let offset = CGPoint(x: currentXOffset, y: yOffset)
                result.updateValue(offset, forKey: size.key)
                currentXOffset += spacing + size.value.width
            }
            
            return result
        }
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
        
        let maxRowWidth = rows.map(\.rowSize.width).reduce(into: 0.0) { $0 = max($0, $1) }
        
        var currentYOffset: CGFloat = .zero
        var result = [Int: CGPoint]()
        
        for row in rows {
            for offset in row.contentOffsets(rowYOffset: currentYOffset, maxRowWidth: maxRowWidth) {
                result.update(with: offset)
            }
            currentYOffset += row.rowSize.height + verticalSpacing
        }
        
        return result
    }
}
