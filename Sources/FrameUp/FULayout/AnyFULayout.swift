//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

public struct AnyFULayout: FULayout {
    public let fuLayoutName: String
    public let id: UUID
    public let alignment: Alignment
    public let itemAlignment: Alignment
    public let fixedSize: Axis.Set
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    private let contentOffsets: ([Int : CGSize]) -> [Int : CGPoint]
    
    public init<L: FULayout>(_ layout: L) {
        fuLayoutName = layout.fuLayoutName
        id = UUID() //layout.id
        alignment = layout.alignment
        itemAlignment = layout.itemAlignment
        fixedSize = layout.fixedSize
        maxItemWidth = layout.maxItemWidth
        maxItemHeight = layout.maxItemHeight
        contentOffsets = layout.contentOffsets
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        contentOffsets(sizes)
    }
    
//    public static func == (lhs: AnyFULayout, rhs: AnyFULayout) -> Bool {
//        lhs.fuLayoutName == rhs.fuLayoutName
//        && lhs.id == rhs.id
//        && lhs.alignment == rhs.alignment
//        && lhs.itemAlignment == rhs.itemAlignment
//        && lhs.fixedSize == rhs.fixedSize
//        && lhs.maxItemWidth == rhs.maxItemWidth
//        && lhs.maxItemHeight == rhs.maxItemHeight
//    }
}

extension AnyFULayout {
//    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
//        let data: Data
//        let layout: AnyFULayout
//        let content: (Data.Element) -> Content
//        
//        public init<L: FULayout>(
//            _ data: Data,
//            layout: L,
//            content: @escaping (Data.Element) -> Content
//        ) {
//            self.data = data
//            self.layout = AnyFULayout(layout)
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
//        let layout: AnyFULayout
//        let content: Content
//        
//        public init<L: FULayout>(
//            _ data: Data,
//            layout: L,
//            @ViewBuilder content: () -> Content
//        ) {
//            self.layout = AnyFULayout(layout)
//            self.content = content()
//        }
//        
//        public var body: some View {
//            layout._view { content }
//        }
//    }
}
