//
//  VStackLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import Foundation
import SwiftUI

public struct ZStackLayout: FULayout {
    public var fuLayoutName: String { String(describing: Self.self) }
    public let id = UUID()
    public let alignment: Alignment
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    
    public var itemAlignment: Alignment { alignment }
    public let fixedSize: Axis.Set = []
    
    public init(
        alignment: Alignment? = nil,
        maxWidth: CGFloat,
        maxHeight: CGFloat
    ) {
        self.alignment = alignment ?? .topLeading
        self.maxItemWidth = maxWidth
        self.maxItemHeight = maxHeight
    }
    
    public func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        let currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        
        for size in sizes.sorted(by: { $0.key < $1.key }) {
            result.updateValue(currentPoint, forKey: size.key)
        }

        return result
    }
}

extension ZStackLayout {
    public struct ForEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
        let data: Data
        let layout: ZStackLayout
        let content: (Data.Element) -> Content
        
        public init(
            _ data: Data,
            alignment: Alignment? = nil,
            maxWidth: CGFloat,
            maxHeight: CGFloat,
            content: @escaping (Data.Element) -> Content
        ) {
            self.data = data
            layout = .init(
                alignment: alignment,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
            self.content = content
        }
        
        public var body: some View {
            layout.forEach(data, content: content)
        }
    }
    
    public struct _View<Content: View>: View {
        @ViewBuilder
        let layout: ZStackLayout
        let content: Content
        
        public init(
            alignment: Alignment? = nil,
            maxWidth: CGFloat,
            maxHeight: CGFloat,
            @ViewBuilder content: () -> Content
        ) {
            layout = .init(
                alignment: alignment,
                maxWidth: maxWidth,
                maxHeight: maxHeight
            )
            self.content = content()
        }
        
        public var body: some View {
            layout._view { content }
        }
    }
}
