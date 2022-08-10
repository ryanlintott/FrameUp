//
//  VStackLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct HStackLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .horizontal
    public var itemAlignment: Alignment { alignment }
    
    public init(
        alignment: VerticalAlignment? = nil,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = Alignment(horizontal: .leading, vertical: alignment ?? .top)
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
            currentPoint.x += spacing + min(size.value.width, maxItemWidth ?? .infinity)
        }

        return result
    }
}

//extension HStackLayout {
//    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
//        let data: Data
//        let layout: HStackLayout
//        let content: (Data.Element) -> Content
//        
//        public init(
//            _ data: Data,
//            alignment: VerticalAlignment? = nil,
//            spacing: CGFloat? = nil,
//            maxHeight: CGFloat,
//            maxItemWidth: CGFloat? = nil,
//            content: @escaping (Data.Element) -> Content
//        ) {
//            self.data = data
//            layout = .init(
//                alignment: alignment,
//                spacing: spacing,
//                maxHeight: maxHeight,
//                maxItemWidth: maxItemWidth
//            )
//            self.content = content
//        }
//        
//        public var body: some View {
//            layout.forEach(data, content: content)
//        }
//    }
//    
//    public struct _View<Content: View>: View {
//        @ViewBuilder
//        let layout: HStackLayout
//        let content: Content
//        
//        public init(
//            alignment: VerticalAlignment? = nil,
//            spacing: CGFloat? = nil,
//            maxHeight: CGFloat,
//            maxItemWidth: CGFloat? = nil,
//            @ViewBuilder content: () -> Content
//        ) {
//            layout = .init(
//                alignment: alignment,
//                spacing: spacing,
//                maxHeight: maxHeight,
//                maxItemWidth: maxItemWidth
//            )
//            self.content = content()
//        }
//        
//        public var body: some View {
//            layout._view { content }
//        }
//    }
//}
