//
//  VMasonryExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-10.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct VMasonryExample: View {
    @State private var items: [Item] = .examples
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var verticalAlignment: FUVerticalAlignment = .top
    @State private var maxWidth: CGFloat = 300
    @State private var columns = 3
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView(.vertical) {
                    VMasonry(alignment: alignment, columns: columns, maxWidth: maxWidth) {
                        ForEach(items) { item in
                            Text(item.value)
                                .padding(12)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .border(Color.red)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: columns)
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
                    Text("Max Width \(maxWidth, specifier: "%.0F")")
                    Button("-") { maxWidth = max(50, maxWidth - 50) }
                    Button("+") { maxWidth = min(600, maxWidth + 50) }
                }
                #else
                Stepper("Max Width \(maxWidth, specifier: "%.0F")", value: $maxWidth, in: 50...600, step: 50)
                #endif
                
                #if os(tvOS)
                HStack {
                    Text("Columns \(columns)")
                    Button("-") { columns = max(2, columns - 1) }
                    Button("+") { columns = min(6, columns + 1) }
                }
                #else
                Stepper("Columns \(columns)", value: $columns, in: 2...6)
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
        .navigationTitle("VMasonry")
    }
}

struct VMasonryExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VMasonryExample()
        }
    }
}
#endif
