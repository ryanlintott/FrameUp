//
//  VStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct VStackFULayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .vertical
    
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        maxWidth: CGFloat,
        maxItemHeight: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxItemHeight
        self.maxItemWidth = maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentYOffset: CGFloat = .zero
        var result = [Int: CGPoint]()

        for size in sizes.sortedByKey() {
            let xOffset: CGFloat
            switch alignment {
            case .leading:
                xOffset = .zero
            case .center:
                xOffset = -size.value.width / 2
            case .trailing:
                xOffset = -size.value.width
            default:
                /// Custom alignments not supported
                xOffset = .zero
            }
            let offset = CGPoint(x: xOffset, y: currentYOffset)
            result.updateValue(offset, forKey: size.key)
            currentYOffset += spacing + min(size.value.height, maxItemHeight ?? .infinity)
        }

        return result
    }
}
