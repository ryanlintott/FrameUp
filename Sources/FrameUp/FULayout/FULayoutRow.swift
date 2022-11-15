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
    
    var contentHeight: CGFloat {
        sizes.map(\.value.height).max() ?? .zero
    }
    
    var contentWidth: CGFloat {
        sizes.map(\.value.width).reduce(into: CGFloat.zero, +=)
    }
    
    var minRowWidth: CGFloat {
        contentWidth + CGFloat(sizes.count - 1) * minSpacing
    }
    
    var rowWidth: CGFloat {
        contentWidth + CGFloat(sizes.count - 1) * spacing
    }
    
    var rowSize: CGSize {
        .init(width: rowWidth, height: contentHeight)
    }
    
    var spacing: CGFloat {
        guard alignment.horizontal == .justified, sizes.count > 1 else { return minSpacing }
        return (maxWidth - contentWidth) / CGFloat(sizes.count - 1)
    }
    
    public init(alignment: FUAlignment, spacing: CGFloat, firstSize: (key: Int, value: CGSize), maxWidth: CGFloat = .infinity) {
        self.alignment = alignment
        self.minSpacing = spacing
        self.sizes = [firstSize.key: firstSize.value]
        self.maxWidth = maxWidth
    }
    
    public init(alignment: FUAlignment, spacing: CGFloat, maxWidth: CGFloat = .infinity) {
        self.alignment = alignment
        self.minSpacing = spacing
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

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            var yOffset = rowYOffset
            
            switch alignment.vertical {
            case .top:
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
}
