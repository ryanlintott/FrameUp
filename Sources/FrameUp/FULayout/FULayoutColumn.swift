//
//  FULayoutColumn.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-09.
//

import SwiftUI

public struct FULayoutColumn: Equatable {
    public let alignment: FUAlignment
    public let minSpacing: CGFloat
    private(set) var sizes: [Int: CGSize]
    private(set) var maxHeight: CGFloat
    private(set) var justifiedHeight: CGFloat?
    
    public init(
        alignment: FUAlignment,
        minSpacing: CGFloat,
        maxHeight: CGFloat = .infinity
    ) {
        self.alignment = alignment
        self.minSpacing = minSpacing
        self.sizes = [:]
        self.maxHeight = maxHeight
    }
}

public extension FULayoutColumn {
    init(
        alignment: FUAlignment,
        minSpacing: CGFloat,
        firstSize: (key: Int, value: CGSize),
        maxHeight: CGFloat = .infinity
    ) {
        self.alignment = alignment
        self.minSpacing = minSpacing
        self.sizes = [firstSize.key: firstSize.value]
        self.maxHeight = maxHeight
    }
    
    var contentWidth: CGFloat {
        sizes.map(\.value.width).max() ?? .zero
    }
    
    var contentHeight: CGFloat {
        sizes.map(\.value.height).reduce(into: CGFloat.zero, +=)
    }
    
    var spacing: CGFloat {
        guard
            alignment.vertical == .justified,
            sizes.count > 1,
            let justifiedHeight
        else { return minSpacing }
        return (justifiedHeight - contentHeight) / CGFloat(sizes.count - 1)
    }
    
    var minColumnHeight: CGFloat {
        contentHeight + CGFloat(sizes.count - 1) * minSpacing
    }
    
    var columnHeight: CGFloat {
        contentHeight + CGFloat(sizes.count - 1) * spacing
    }
    
    var minColumnSize: CGSize {
        .init(width: contentWidth, height: minColumnHeight)
    }
    
    var columnSize: CGSize {
        .init(width: contentWidth, height: columnHeight)
    }
    
    @discardableResult
    mutating func append(_ element: (key: Int, value: CGSize)) -> Bool {
        let newHeight = minColumnHeight + minSpacing + element.value.height
        guard newHeight <= maxHeight else { return false }
        sizes.update(with: element)
        return true
    }
    
    func contentOffsets(columnXOffset: CGFloat, alignmentHeight: CGFloat? = nil) -> [Int: CGPoint] {
        var currentYOffset = 0.0
        
        if let alignmentHeight {
            switch alignment.vertical {
            case .top, .justified:
                break
            case .center:
                currentYOffset += (alignmentHeight - columnHeight) / 2
            case .bottom:
                currentYOffset += alignmentHeight - columnHeight
            }
        }
        
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            var xOffset = columnXOffset
            
            switch alignment.horizontal {
            case .leading, .justified:
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
    
    func justified(height: CGFloat) -> Self {
        var column = self
        column.justifiedHeight = height
        return column
    }
}

public extension Array<FULayoutColumn> {
    /// The largest min column height
    var maxMinColumnHeight: CGFloat {
        map(\.minColumnHeight).max() ?? 0
    }
    
    /// Sets the justified height for all columns.
    /// - Parameters:
    ///   - height: Optional width to use for justification. If none provided, the largest minWidth of the provided rows will be used.
    ///   - skipLast: Skips justifying the last column if true. (Default: false)
    mutating func justifyIfNecessary(height: CGFloat? = nil, skipLast: Bool = false) {
        let height = height ?? maxMinColumnHeight
        
        let justified = map { column in
            guard column.alignment.vertical == .justified else { return column }
            return column.justified(height: height)
        }
        
        if skipLast, let last {
            self = justified.dropLast() + [last]
        } else {
            self = justified
        }
    }
}
