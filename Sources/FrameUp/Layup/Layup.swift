//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public struct LayupSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}

public protocol Layup: Identifiable {
    var id: UUID { get }
    var alignment: Alignment { get }
    var itemAlignment: Alignment { get }
    var fixedSize: Axis.Set { get }
    var maxItemWidth: CGFloat? { get }
    var maxItemHeight: CGFloat? { get }
    func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint]
}

extension Layup {
    public func rect(positions: [Int: CGPoint], sizes: [Int: CGSize]) -> CGRect {
        var minX: CGFloat = 0
        var minY: CGFloat = 0
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        let frames = sizes.forEach { size in
            guard let offset = positions[size.key] else {
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
}

struct AnyLayup: Layup {
    let id: UUID
    let alignment: Alignment
    let itemAlignment: Alignment
    let fixedSize: Axis.Set
    let maxItemWidth: CGFloat?
    let maxItemHeight: CGFloat?
    private let contentOffsets: ([Int : CGSize]) -> [Int : CGPoint]
    
    init<L: Layup>(_ layup: L) {
        id = layup.id
        alignment = layup.alignment
        itemAlignment = layup.itemAlignment
        fixedSize = layup.fixedSize
        maxItemWidth = layup.maxItemWidth
        maxItemHeight = layup.maxItemHeight
        contentOffsets = layup.contentOffsets
    }
    
    func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        contentOffsets(sizes)
    }
}

struct LayupView<Content: View>: View {
    let layup: AnyLayup
    let content: Content
    
    init<L: Layup>(layup: L, @ViewBuilder content: () -> Content) {
        self.layup = AnyLayup(layup)
        self.content = content()
    }
    
    @State private var contentPositions: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    var body: some View {
        ZStack(alignment: layup.alignment) {
            _VariadicView.Tree(VariadicLayupRoot(layup: layup, contentPositions: contentPositions)) {
                content
            }
        }
        .frame(frameSize, alignment: layup.alignment)
        .fixedSize()
        .onPreferenceChange(LayoutSizeKey.self) {
            contentPositions = layup.contentOffsets(sizes: $0)
            frameSize = layup.rect(positions: contentPositions, sizes: $0).size
        }
        .id(layup.id)
    }
}

fileprivate struct VariadicLayupRoot<L: Layup>: _VariadicView_MultiViewRoot {
    let layup: L
    let contentPositions: [Int: CGPoint]
    
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        ForEach(Array(zip(children, children.indices)), id: \.0.id) { (child, index) in
            child
                .overlay(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: LayupSizeKey.self, value: [index: proxy.size])
                    }
                )
                .fixedSize(
                    horizontal: layup.fixedSize.contains(.horizontal),
                    vertical: layup.fixedSize.contains(.vertical)
                )
                .frame(
                    maxWidth: layup.maxItemWidth,
                    maxHeight: layup.maxItemHeight,
                    alignment: layup.itemAlignment
                )
                .alignmentGuide(layup.alignment.horizontal) { d in
                    -(contentPositions[index]?.x ?? .zero)
                }
                .alignmentGuide(layup.alignment.vertical) { d in
                    -(contentPositions[index]?.y ?? .zero)
                }
        }
    }
}
