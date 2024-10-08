//
//  HFlowLayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-12.
//

import FrameUp
import SwiftUI

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct HFlowLayoutExample: View {
    @State private var items: [Item] = .examples
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var verticalAlignment: FUVerticalAlignment = .top
    @State private var maxWidth: CGFloat = 300
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView(.vertical) {
                    HFlowLayout(alignment: alignment) {
                        ForEach(items) { item in
                            Text(item.value)
                                .padding(12)
                                .foregroundColor(.white)
                                .frame(height: CGFloat(item.value.count) * 6)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .border(Color.red)
                    .frame(maxWidth: maxWidth)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: maxWidth)
                .animation(.default, value: horizontalAlignment)
                .animation(.default, value: verticalAlignment)
                .animation(.default, value: layoutDirection)
            )
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
                    ForEach(FUHorizontalAlignment.allCases) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                
                #if os(tvOS)
                HStack {
                    Text("Max Width \(maxWidth, specifier: "%.0F")")
                    Button("-") { maxWidth = max(50, maxWidth - 50) }
                    Button("+") { maxWidth = min(600, maxWidth + 50) }
                }
                #else
                Stepper("Max Width \(maxWidth, specifier: "%.0F")", value: $maxWidth, in: 50...600, step: 50)
                #endif
                
                Picker("Layout Direction", selection: $layoutDirection) {
                    ForEach(LayoutDirection.allCases, id: \.self) { direction in
                        Text(direction == .leftToRight ? "Left to Right" : "Right to Left")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .navigationTitle("HFlowLayout")
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct HFlowLayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HFlowLayoutExample()
        }
    }
}
