//
//  FULayoutRow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-09.
//

import SwiftUI

public struct FULayoutRow: Equatable {
    public let minSpacing: CGFloat
    public let alignment: FUAlignment
    private(set) var sizes: [Int: CGSize]
    private(set) var maxWidth: CGFloat
    private(set) var justifiedWidth: CGFloat? = nil
    
    var contentHeight: CGFloat {
        sizes.map(\.value.height).max() ?? .zero
    }
    
    var contentWidth: CGFloat {
        sizes.map(\.value.width).reduce(into: CGFloat.zero, +=)
    }
    
    var spacing: CGFloat {
        guard
            alignment.horizontal == .justified,
            sizes.count > 1,
            let justifiedWidth
        else { return minSpacing }
        return (justifiedWidth - contentWidth) / CGFloat(sizes.count - 1)
    }
    
    var minRowWidth: CGFloat {
        contentWidth + CGFloat(sizes.count - 1) * minSpacing
    }
    
    var rowWidth: CGFloat {
        contentWidth + CGFloat(sizes.count - 1) * spacing
    }
    
    var minRowSize: CGSize {
        .init(width: minRowWidth, height: contentHeight)
    }
    
    var rowSize: CGSize {
        .init(width: rowWidth, height: contentHeight)
    }
    
    public init(
        alignment: FUAlignment,
        minSpacing: CGFloat,
        firstSize: (key: Int, value: CGSize),
        maxWidth: CGFloat = .infinity
    ) {
        self.alignment = alignment
        self.minSpacing = minSpacing
        self.sizes = [firstSize.key: firstSize.value]
        self.maxWidth = maxWidth
    }
    
    public init(
        alignment: FUAlignment,
        minSpacing: CGFloat,
        maxWidth: CGFloat = .infinity
    ) {
        self.alignment = alignment
        self.minSpacing = minSpacing
        self.sizes = [:]
        self.maxWidth = maxWidth
    }
    
    @discardableResult
    mutating func append(_ element: (key: Int, value: CGSize)) -> Bool {
        let newWidth = minRowWidth + minSpacing + element.value.width
        guard newWidth <= maxWidth else { return false }
        sizes.update(with: element)
        return true
    }
    
    public func contentOffsets(rowYOffset: CGFloat) -> [Int: CGPoint] {
        var currentXOffset = 0.0
        
        switch alignment.horizontal {
        case .leading, .justified:
            break
        case .center:
            currentXOffset -= rowSize.width / 2
        case .trailing:
            currentXOffset -= rowSize.width
        }
        
        var result = [Int: CGPoint]()

        for size in sizes.sortedByKey() {
            var yOffset = rowYOffset
            
            switch alignment.vertical {
            case .top, .justified:
                break
            case .center:
                yOffset += (rowSize.height - size.value.height) / 2
            case .bottom:
                yOffset += rowSize.height - size.value.height
            }
            let offset = CGPoint(x: currentXOffset, y: yOffset)
            result.updateValue(offset, forKey: size.key)
            currentXOffset += spacing + size.value.width
        }
        
        return result
    }
    
    public func justified(width: CGFloat) -> Self {
        var row = self
        row.justifiedWidth = width
        return row
    }
}

extension Array<FULayoutRow> {
    /// Sets the justified width for all rows to equal the minimum width of the widest row if alignment on all rows is set to justified.
    mutating func justifyIfNecessary() {
        if
            allSatisfy({ $0.alignment.horizontal == .justified }),
            let maxRowWidth = map(\.minRowWidth).max()
        {
            self = map { $0.justified(width: maxRowWidth) }
        }
    }
}
