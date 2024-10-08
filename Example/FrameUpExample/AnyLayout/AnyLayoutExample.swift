//
//  AnyLayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-05-31.
//

import FrameUp
import SwiftUI

enum LayoutStyleExamples: Int, CaseIterable, Hashable, Equatable, Comparable {
    case vStack
    case hStack
    case zStack
    case vFlow
    case hFlow
    case vMasonry
    
    func layout(maxSize: CGSize) -> Layout {
        switch self {
        case .vStack:
            return VStackLayoutStyle(maxWidth: 300).layout
        case .zStack:
            return ZStackLayoutStyle(maxWidth: maxSize.width, maxHeight: maxSize.height).layout
        case .hStack:
            return HStackLayoutStyle(maxHeight: maxSize.height).layout
        case .vFlow:
            return VFlowLayoutStyle(maxWidth: 300).layout
        case .hFlow:
            return HFlowLayoutStyle(maxHeight: 200).layout
        case .vMasonry:
            return VMasonryLayoutStyle(columns: 3, maxWidth: 230).layout
        }
    }
    
    var name: String {
        switch self {
        case .vStack:
            return "VStack"
        case .hStack:
            return "HStack"
        case .zStack:
            return "ZStack"
        case .vFlow:
            return "VFlow"
        case .hFlow:
            return "HFlow"
        case .vMasonry:
            return "VMasonry"
        }
    }
    
    func next() -> Self {
        .init(rawValue: (self.rawValue + 1) % Self.allCases.count) ?? .vFlow
    }
    
    static func < (lhs: LayoutStyleExamples, rhs: LayoutStyleExamples) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct AnyLayoutExample: View {
    let items = ["These", "Items", "can be arranged", "into any", "layout", "you like", "with", "AnyStack"]
        .map { Item(id: UUID(), value: $0) }
    
    @State private var layoutStyle: LayoutStyleExamples = .vMasonry
    
    var body: some View {
        GeometryReader { proxy in
            let layout = layoutStyle.layout(maxSize: proxy.size)
            
            AnyLayout(items, layout: layout) { item in
                Text(item.value)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .clipped()
            }
            .background(Color.gray.opacity(0.5))
            .animation(.default, value: layoutStyle)
        }
        .onTapGesture {
            layoutStyle = layoutStyle.next()
        }
        .navigationTitle("AnyLayout \(layoutStyle.name)")
    }
}

struct AnyLayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EmptyView()
            AnyLayoutExample()
        }
    }
}
