//
//  VStackLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct VStackLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    
    public let alignment: Alignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .vertical
    public var itemAlignment: Alignment { alignment }
    
    public init(
        alignment: HorizontalAlignment? = nil,
        spacing: CGFloat? = nil,
        maxWidth: CGFloat,
        maxItemHeight: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: alignment ?? .leading, vertical: .top)
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxItemHeight
        self.maxItemWidth = maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
            currentPoint.y += spacing + min(size.value.height, maxItemHeight ?? .infinity)
        }

        return result
    }
}

extension VStackLayout {
    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
        let data: Data
        let layout: VStackLayout
        let content: (Data.Element) -> Content
        
        public init(
            _ data: Data,
            alignment: HorizontalAlignment? = nil,
            spacing: CGFloat? = nil,
            maxWidth: CGFloat,
            maxItemHeight: CGFloat? = nil,
            content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            layout = .init(
                alignment: alignment,
                spacing: spacing,
                maxWidth: maxWidth,
                maxItemHeight: maxItemHeight
            )
            self.content = content
        }
        
        public var body: some View {
            layout.forEach(data, content: content)
        }
    }
    
    public struct _View<Content: View>: View {
        @ViewBuilder
        let layout: VStackLayout
        let content: Content
        
        public init(
            alignment: HorizontalAlignment? = nil,
            spacing: CGFloat? = nil,
            maxWidth: CGFloat,
            maxItemHeight: CGFloat? = nil,
            @ViewBuilder content: () -> Content
        ) {
            layout = .init(
                alignment: alignment,
                spacing: spacing,
                maxWidth: maxWidth,
                maxItemHeight: maxItemHeight
            )
            self.content = content()
        }
        
        public var body: some View {
            layout._view { content }
        }
    }
}
