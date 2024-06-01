//
//  LegacyHFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

/// A view that creates views based on a collection of data from left to right, adding rows when needed.
///
/// Each row height will be determined by the tallest element. The overall frame size will fit to the size of the laid out content.
///
/// A maximum width must be provided but `WidthReader` can be used to get the value (especially helpful when inside a `ScrollView`).
///
/// Example:
///
///     WidthReader { width in
///         HFlow(["Hello", "World", "More Text"], maxWidth: width) { item in
///             Text(item.value)
///                 .padding(12)
///                 .foregroundColor(.white)
///                 .background(Color.blue)
///                 .cornerRadius(12)
///         }
///     }
///
/// Adding or removing elements may not animate as intended as element ids are based on their index.
@available(*, deprecated, message: "Use HFlow().forEach instead")
public struct HFlowLegacy<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let maxWidth: CGFloat
    let maxRowHeight: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var contentPositions: [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var rowHeight: CGFloat = .zero

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero && currentPoint.x + size.value.width > maxWidth {
                currentPoint.x = .zero
                currentPoint.y += rowHeight + verticalSpacing
                rowHeight = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.x += size.value.width + horizontalSpacing
            rowHeight = min(max(rowHeight, size.value.height), maxRowHeight)
        }
        
        return result
    }
    
    /// Creates a flowing arrangement of views based on the supplied data from left to right, adding rows when needed.
    /// - Parameters:
    ///   - data: Collection of data eg. an array of strings.
    ///   - maxWidth: Maximum available width. Final width will be based on the width of content views.
    ///   - maxRowHeight: Maximum available row height. Actual row heights will be based on the height of the tallest content view.
    ///   - horizontalSpacing: Horizontal spacing between elements. Default: 10
    ///   - verticalSpacing: Vertical spacing between rows. Default: 10
    ///   - content: Content view that takes a data element as a parameter.
    public init(_ data: Data, maxWidth: CGFloat, maxRowHeight: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.maxWidth = maxWidth
        self.maxRowHeight = maxRowHeight
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data, id: \.0.id) { (item, index) in
                content(item)
                    .overlay(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: FlowContentSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .frame(maxWidth: maxWidth, maxHeight: maxRowHeight, alignment: .topLeading)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        -(contentPositions[index]?.x ?? .zero)
                    }
                    .alignmentGuide(.top) { d in
                        -(contentPositions[index]?.y ?? .zero)
                    }
            }
        }
        .onPreferenceChange(FlowContentSizeKey.self) {
            self.sizes = $0
        }
    }
}
