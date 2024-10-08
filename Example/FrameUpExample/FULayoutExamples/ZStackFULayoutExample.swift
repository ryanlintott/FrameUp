//
//  ZStackFULayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-12.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct ZStackFULayoutExample: View {
    @State private var items: [Item] = .examples
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var verticalAlignment: FUVerticalAlignment = .top
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                Color.clear.overlay(
                    ZStackFULayout(alignment: alignment, maxWidth: proxy.size.width, maxHeight: proxy.size.height) {
                        ForEach(items) { item in
                            Text(item.value)
                                .padding(12)
                                .frame(height: CGFloat(item.value.count) * 6)
                                .border(Color.blue)
                        }
                    }
                        .background(Color.gray.opacity(0.5))
                        .border(Color.red)
                        .padding()
                )
            }
            .animation(.default, value: items)
            .animation(.default, value: horizontalAlignment)
            .animation(.default, value: verticalAlignment)
            .animation(.default, value: layoutDirection)
            .environment(\.layoutDirection, layoutDirection)
            
            VStack {
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append(Item(value: items.randomElement()?.value ?? "New Item")) }
                        .padding()
                }
                
                Picker("Vertical Alignment", selection: $verticalAlignment) {
                    ForEach([FUVerticalAlignment.top, .center, .bottom]) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Horizontal Alignment", selection: $horizontalAlignment) {
                    ForEach([FUHorizontalAlignment.leading, .center, .trailing]) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Layout Direction", selection: $layoutDirection) {
                    ForEach(LayoutDirection.allCases, id: \.self) { direction in
                        Text(direction == .leftToRight ? "Left to Right" : "Right to Left")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .navigationTitle("ZStackFULayout")
    }
}

struct ZStackFULayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ZStackFULayoutExample()
        }
    }
}
#endif
