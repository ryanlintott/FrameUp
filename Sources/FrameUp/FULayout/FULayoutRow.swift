//
//  FULayoutRow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-09.
//

import SwiftUI

public struct FULayoutRow: Equatable {
    public let spacing: CGFloat
    public let alignment: FUAlignment
    private(set) var sizes: [Int: CGSize]
    private(set) var rowSize: CGSize
    
    public init(alignment: FUAlignment, spacing: CGFloat, firstSize: (key: Int, value: CGSize)) {
        self.alignment = alignment
        self.spacing = spacing
        self.sizes = [firstSize.key: firstSize.value]
        self.rowSize = firstSize.value
    }
    
    public init(alignment: FUAlignment, spacing: CGFloat, height: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
        self.sizes = [:]
        self.rowSize = CGSize(width: .zero, height: height)
    }
    
    @discardableResult
    mutating func append(_ element: (key: Int, value: CGSize), maxWidth: CGFloat = .infinity) -> Bool {
        let newWidth = rowSize.width + element.value.width + spacing
        guard newWidth <= maxWidth else { return false }
        sizes.update(with: element)
        rowSize.width = newWidth
        rowSize.height = max(rowSize.height, element.value.height)
        return true
    }
    
    public func contentOffsets(rowYOffset: CGFloat) -> [Int: CGPoint] {
        var currentXOffset = 0.0
        
        switch alignment.horizontal {
        case .leading:
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
