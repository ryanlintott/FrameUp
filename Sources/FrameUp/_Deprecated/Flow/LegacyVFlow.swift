//
//  LegacyVFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

/// A view that creates views based on a collection of data from top to bottom, adding columns when needed.
///
/// Each column width will be determined by the widest element. The overall frame size will fit to the size of the laid out content.
///
/// A maximum height must be provided but `HeightReader` can be used to get the value (especially helpful when inside a `ScrollView`).
///
/// Example:
///
///     HeightReader { height in
///         VFlow(["Hello", "World", "More Text"], maxHeight: height) { item in
///             Text(item.value)
///                 .padding(12)
///                 .foregroundColor(.white)
///                 .background(Color.blue)
///                 .cornerRadius(12)
///         }
///     }
///
///
/// Adding or removing elements may not animate as intended as element ids are based on their index.
@available(*, deprecated, message: "Use VFlow().forEach instead")
public struct VFlowLegacy<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let maxHeight: CGFloat
    let maxColumnWidth: CGFloat
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var sizes: [Int: CGSize] = [:]
    
    var contentPositions: [Int: CGPoint] {
        var currentPoint: CGPoint = .zero
        var result = [Int: CGPoint]()
        var columnWidth: CGFloat = .zero

        for size in sizes.sorted(by: { $0.key < $1.key }) {
            if currentPoint != .zero && currentPoint.y + size.value.height > maxHeight {
                currentPoint.y = .zero
                currentPoint.x += columnWidth + horizontalSpacing
                columnWidth = .zero
            }
            result.updateValue(currentPoint, forKey: size.key)
            
            currentPoint.y += size.value.height + verticalSpacing
            columnWidth = min(max(columnWidth, size.value.width), maxColumnWidth)
        }
        
        return result
    }
    
    /// Creates a flowing arrangement of views based on the supplied data from top to bottom, adding columns when needed.
    /// - Parameters:
    ///   - data: Collection of data eg. an array of strings.
    ///   - maxHeight: Maximum available height. Final height will be based on the height of content views.
    ///   - maxColumnWidth: Maximum available column width. Actual column widths will be based on the width of the widest content view.
    ///   - horizontalSpacing: Horizontal spacing between elements. Default: 10
    ///   - verticalSpacing: Vertical spacing between rows. Default: 10
    ///   - content: Content view that takes a data element as a parameter.
    public init(_ data: Data, maxHeight: CGFloat, maxColumnWidth: CGFloat = .infinity, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.maxHeight = maxHeight
        self.maxColumnWidth = maxColumnWidth
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }
    
    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(data, id: \.0.id) { (item, index) in
                content(item)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: FlowContentSizeKey.self, value: [index: proxy.size])
                        }
                    )
                    .frame(maxWidth: maxColumnWidth, maxHeight: maxHeight, alignment: .topLeading)
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
