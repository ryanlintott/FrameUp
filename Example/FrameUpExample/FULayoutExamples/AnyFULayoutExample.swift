//
//  AnyFULayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-07-18.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

fileprivate func exampleLayouts(size: CGSize) -> [any FULayout] {
    [
        VFlow(alignment: .topLeading, maxHeight: size.height),
        VFlow(alignment: .top, maxHeight: size.height),
        VFlow(alignment: .topTrailing, maxHeight: size.height),
        VFlow(alignment: .leading, maxHeight: size.height),
        VFlow(alignment: .center, maxHeight: size.height),
        VFlow(alignment: .trailing, maxHeight: size.height),
        VFlow(alignment: .bottomLeading, maxHeight: size.height),
        VFlow(alignment: .bottom, maxHeight: size.height),
        VFlow(alignment: .bottomTrailing, maxHeight: size.height),

        VMasonry(alignment: .top, columns: 3, maxWidth: size.width),
        VMasonry(alignment: .center, columns: 3, maxWidth: size.width),
        VMasonry(alignment: .bottom, columns: 3, maxWidth: size.width),

        VStackFULayout(alignment: .leading, maxWidth: size.width),
        VStackFULayout(alignment: .center, maxWidth: size.width),
        VStackFULayout(alignment: .trailing, maxWidth: size.width),

        HFlow(alignment: .topLeading, maxWidth: size.width),
        HFlow(alignment: .top, maxWidth: size.width),
        HFlow(alignment: .topTrailing, maxWidth: size.width),
        HFlow(alignment: .leading, maxWidth: size.width),
        HFlow(alignment: .center, maxWidth: size.width),
        HFlow(alignment: .trailing, maxWidth: size.width),
        HFlow(alignment: .bottomLeading, maxWidth: size.width),
        HFlow(alignment: .bottom, maxWidth: size.width),
        HFlow(alignment: .bottomTrailing, maxWidth: size.width),
        
        HMasonry(alignment: .leading, rows: 3, maxHeight: size.height),
        HMasonry(alignment: .center, rows: 3, maxHeight: size.height),
        HMasonry(alignment: .trailing, rows: 3, maxHeight: size.height),
        
        HStackFULayout(alignment: .top, maxHeight: size.height),
        HStackFULayout(alignment: .center, maxHeight: size.height),
        HStackFULayout(alignment: .bottom, maxHeight: size.height),
        
        ZStackFULayout(alignment: .topLeading, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .top, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .topTrailing, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .leading, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .center, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .trailing, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .bottomLeading, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .bottom, maxWidth: size.width, maxHeight: size.height),
        ZStackFULayout(alignment: .bottomTrailing, maxWidth: size.width, maxHeight: size.height)
    ]
}

struct AnyFULayoutExample: View {
    var body: some View {
        VStack {
            TabView {
                AnyFULayout_ViewExample()
                    .tabItem { Label("Layout", systemImage: "rectangle.3.group") }
                
                AnyFULayoutForEachExample()
                    .tabItem { Label(".forEach", systemImage: "list.dash") }
            }
        }
    }
}

struct AnyFULayout_ViewExample: View {
    @State private var items = ["These", "Items", "can be arranged", "into any", "layout", "you like", "with", "FrameUp"]
        .map { Item(id: UUID(), value: $0) }
    @State private var layoutIndex = 0
    
    @State private var layoutDirection: LayoutDirection = .leftToRight
    var layoutDirectionImageName: String {
        switch layoutDirection {
        case .rightToLeft: return "arrow.left"
        default: return "arrow.right"
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let layouts = exampleLayouts(size: proxy.size)
            let layout = layouts[layoutIndex].anyFULayout
            
            VStack {
                Text(layout.fuLayoutName)
                    .font(.subheadline)
                
                Color.clear.overlay(
                    ZStack(alignment: .top) {
                        layout {
                            ForEach(items) { item in
                                Text(item.value)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(height: CGFloat(item.value.count) * 8)
                                    .frame(
                                        maxWidth: layout.fuLayoutName.contains("VMasonry") ? .infinity : nil,
                                        maxHeight: layout.fuLayoutName.contains("HMasonry") ? .infinity : nil
                                    )
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .background(Color.gray.opacity(0.5))
                        .border(Color.red)
                        .animation(.default, value: layoutIndex)
                        .animation(.default, value: items)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .environment(\.layoutDirection, layoutDirection)
                        
                        
                    }
                    , alignment: .top
                )
                .clipped()
                
                Spacer()
                
                Button("Next Layout") {
                    layoutIndex = (layoutIndex + 1) % layouts.count
                }
                
                Button {
                    layoutDirection = layoutDirection == .leftToRight ? .rightToLeft : .leftToRight
                } label: {
                    Label("Layout Direction", systemImage: layoutDirectionImageName)
                }
                .padding()
                
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append(Item(value: items.randomElement()?.value ?? "New Item")) }
                        .padding()
                }
            }
        }
    }
}

struct AnyFULayoutForEachExample: View {
    @State private var items = ["These", "Items", "can be arranged", "into any", "layout", "you like", "with", "FrameUp"]
        .map { Item(id: UUID(), value: $0) }
    @State private var layoutIndex = 0
    
    @State private var layoutDirection: LayoutDirection = .leftToRight
    var layoutDirectionImageName: String {
        switch layoutDirection {
        case .rightToLeft: return "arrow.left"
        default: return "arrow.right"
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            let layouts = exampleLayouts(size: proxy.size)
            let layout = layouts[layoutIndex].anyFULayout
                
            VStack {
                Text(layout.fuLayoutName)
                    .font(.subheadline)
                
                Color.clear.overlay(
                    ZStack(alignment: .top) {
                        layout.forEach(items) { item in
                            Text(item.value)
                                .padding(12)
                                .foregroundColor(.white)
                                .frame(height: CGFloat(item.value.count) * 8)
                                .frame(
                                    maxWidth: layout.fuLayoutName.contains("VMasonry") ? .infinity : nil,
                                    maxHeight: layout.fuLayoutName.contains("HMasonry") ? .infinity : nil
                                )
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .background(Color.gray.opacity(0.5))
                        .border(Color.red)
                        .animation(.spring(), value: layoutIndex)
                        .animation(.spring(), value: items)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .environment(\.layoutDirection, layoutDirection)
                        
                        
                    }
                    , alignment: .top
                )
                .clipped()
                
                Spacer()
                
                Button("Next Layout") {
                    layoutIndex = (layoutIndex + 1) % layouts.count
                }
                
                Button {
                    layoutDirection = layoutDirection == .leftToRight ? .rightToLeft : .leftToRight
                } label: {
                    Label("Layout Direction", systemImage: layoutDirectionImageName)
                }
                .padding()
                
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append(Item(value: items.randomElement()?.value ?? "New Item")) }
                        .padding()
                }
            }
        }
        .navigationTitle("AnyFULayout")
    }
}

struct AnyFULayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnyFULayoutExample()
        }
    }
}
#endif
