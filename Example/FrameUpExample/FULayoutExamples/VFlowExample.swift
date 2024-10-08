//
//  VFlowExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-14.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct VFlowExample: View {
    @State private var items: [Item] = .examples
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var verticalAlignment: FUVerticalAlignment = .top
    @State private var maxHeight: CGFloat = 300
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView(.horizontal) {
                    VFlow(alignment: alignment, maxHeight: maxHeight) {
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
                    .frame(maxHeight: maxHeight, alignment: .top)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: maxHeight)
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
                    ForEach(FUVerticalAlignment.allCases) {
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
                
                #if os(tvOS)
                HStack {
                    Text("Max Height \(maxHeight, specifier: "%.0F")")
                    Button("-") { maxHeight = max(50, maxHeight - 50) }
                    Button("+") { maxHeight = min(600, maxHeight + 50) }
                }
                #else
                Stepper("Max Height \(maxHeight, specifier: "%.0F")", value: $maxHeight, in: 50...600, step: 50)
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
        .navigationTitle("VFlow")
    }
}

struct VFlowExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VFlowExample()
        }
    }
}
#endif
