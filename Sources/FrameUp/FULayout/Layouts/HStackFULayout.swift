//
//  HStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct HStackFULayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: VerticalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .horizontal
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentXOffset = 0.0
        var result = [Int: CGPoint]()

        for size in sizes.sortedByKey() {
            let yOffset: CGFloat
            switch alignment {
            case .top:
                yOffset = .zero
            case .center:
                yOffset = -size.value.height / 2
            case .bottom:
                yOffset = -size.value.height
            default:
                /// Custom alignments not supported
                yOffset = .zero
            }
            let offset = CGPoint(x: currentXOffset, y: yOffset)
            result.updateValue(offset, forKey: size.key)
            currentXOffset += spacing + min(size.value.width, maxItemWidth ?? .infinity)
        }

        return result
    }
}
