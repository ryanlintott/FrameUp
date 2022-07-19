//
//  ViewLayout.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-06-01.
//

import SwiftUI

public protocol LayoutStyle: Identifiable {
    var id: UUID { get }
    var alignment: Alignment { get }
    var itemAlignment: Alignment { get }
    var fixedSize: Axis.Set { get }
    var maxItemWidth: CGFloat? { get }
    var maxItemHeight: CGFloat? { get }
    func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint]
}

public extension LayoutStyle {
    var layout: Layout {
        Layout(
            alignment: alignment,
            itemAlignment: itemAlignment,
            fixedSize: fixedSize,
            maxItemWidth: maxItemWidth,
            maxItemHeight: maxItemWidth,
            contentOffsets: contentOffsets
        )
    }
}

public struct Layout: LayoutStyle {
    public let id = UUID()
    public let alignment: Alignment
    public let itemAlignment: Alignment
    public var fixedSize: Axis.Set
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    public let contentOffsets: (_ sizes: [Int: CGSize]) -> [Int: CGPoint]
    public func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        self.contentOffsets(sizes)
    }
    
    public func rect(positions: [Int: CGPoint], sizes: [Int: CGSize]) -> CGRect {
        var minX: CGFloat = 0
        var minY: CGFloat = 0
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        let _ = sizes.forEach { size in
            guard let offset = positions[size.key] else {
                return
            }
            var x = offset.x
            var y = offset.y
            
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
}

extension Layout {
    static func style<T: LayoutStyle>(_ style: T) -> Self {
        style.layout
    }
}

