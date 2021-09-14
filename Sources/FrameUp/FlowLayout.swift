//
//  FlowLayout.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-10.
//

import SwiftUI

//struct SizeKey: PreferenceKey {
//    typealias Value = [CGSize]
//    static let defaultValue: [CGSize] = []
//    static func reduce(value: inout Value, nextValue: () -> Value) {
//        value.append(contentsOf: nextValue())
//    }
//}
//
//struct FlowLayout<Element: Identifiable, Cell: View>: View {
//    var items: [Element]
//    var cell: (Element) -> Cell
//    let horizontalSpacing: CGFloat
//    let verticalSpacing: CGFloat
//    
//    @State private var sizes: [CGSize] = []
//    @State private var containerWidth: CGFloat = 0
//    
//    init(items: [Element], cell: @escaping (Element) -> Cell, horizontalSpacing: CGFloat = 10, verticalSpacing: CGFloat = 10) {
//        self.items = items
//        self.cell = cell
//        self.horizontalSpacing = horizontalSpacing
//        self.verticalSpacing = verticalSpacing
//    }
//    
//    var body: some View {
//        let laidout = layout(sizes: sizes, containerWidth: containerWidth)
//        
//        return VStack(spacing: 0) {
//            GeometryReader { proxy in
//                Color.clear
//                    .preference(key: SizeKey.self, value: [proxy.size])
//            }
//            .frame(height: 0)
//            .onPreferenceChange(SizeKey.self) { value in
//                self.containerWidth = value[0].width
//            }
//            
//            ZStack(alignment: .topLeading) {
//                ForEach(Array(zip(items, items.indices)), id: \.0.id) { (item, index) in
//                    cell(item)
//                        .fixedSize()
//                        .background(
//                            GeometryReader { proxy in
//                                Color.clear
//                                    .preference(key: SizeKey.self, value: [proxy.size])
//                            }
//                        )
//                        .alignmentGuide(.leading) { d in
//                            guard !laidout.isEmpty else { return 0 }
//                            return -laidout[index].x
//                        }
//                        .alignmentGuide(.top) { d in
//                            guard !laidout.isEmpty else { return 0 }
//                            return -laidout[index].y
//                        }
//                }
//            }
//            .onPreferenceChange(SizeKey.self) {
//                // don't need to store ids as well since they order remains the same
//                self.sizes = $0
//            }
//            .background(Color.red)
//        }
//    }
//    
//    func layout(sizes: [CGSize], containerWidth: CGFloat) -> [CGPoint] {
//        var currentPoint: CGPoint = .zero
//        var result = [CGPoint]()
//        var lineHeight: CGFloat = 0
//        for size in sizes {
//            if currentPoint.x + size.width > containerWidth {
//                currentPoint.x = 0
//                currentPoint.y += lineHeight + verticalSpacing
//                lineHeight = 0
//            }
//            result.append(currentPoint)
//            currentPoint.x += size.width + horizontalSpacing
//            lineHeight = max(lineHeight, size.height)
//        }
//        return result
//    }
//}
