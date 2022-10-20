//
//  FULayoutColumn.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-09.
//

import SwiftUI

public struct FULayoutColumn: Equatable {
    public let spacing: CGFloat
    public let alignment: FUAlignment
    private(set) var sizes: [Int: CGSize]
    private(set) var columnSize: CGSize
    
    public init(alignment: FUAlignment, spacing: CGFloat, firstSize: (key: Int, value: CGSize)) {
        self.alignment = alignment
        self.spacing = spacing
        self.sizes = [firstSize.key: firstSize.value]
        self.columnSize = firstSize.value
    }
    
    public init(alignment: FUAlignment, spacing: CGFloat, width: CGFloat) {
        self.alignment = alignment
        self.spacing = spacing
        self.sizes = [:]
        self.columnSize = CGSize(width: width, height: .zero)
    }
    
    @discardableResult
    mutating func append(_ element: (key: Int, value: CGSize), maxHeight: CGFloat = .infinity) -> Bool {
        let newHeight = columnSize.height + element.value.height + spacing
        guard newHeight <= maxHeight else { return false }
        sizes.update(with: element)
        columnSize.height = newHeight
        columnSize.width = max(columnSize.width, element.value.width)
        return true
    }
    
    public func contentOffsets(columnXOffset: CGFloat) -> [Int: CGPoint] {
        var currentYOffset = 0.0
        
        switch alignment.vertical {
        case .top:
            break
        case .center:
            currentYOffset -= columnSize.height / 2
        case .bottom:
            currentYOffset -= columnSize.height
        }
        
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            var xOffset = columnXOffset
            switch alignment.horizontal {
            case .leading:
                break
            case .center:
                xOffset += (columnSize.width - size.value.width) / 2
            case .trailing:
                xOffset += columnSize.width - size.value.width
            }
            let offset = CGPoint(x: xOffset, y: currentYOffset)
            result.updateValue(offset, forKey: size.key)
            currentYOffset += spacing + size.value.height
        }
        
        return result
    }
}
