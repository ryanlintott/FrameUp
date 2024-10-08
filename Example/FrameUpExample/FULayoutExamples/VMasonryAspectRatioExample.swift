//
//  VMasonryAspectRatioExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-10.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct VMasonryAspectRatioExample: View {
    @State private var items: [Item] = [1, 1.3, 1.4, 0.5, 0.7, 1.1, 2, 0.6].map { .init(value: $0) }
    @State private var verticalAlignment: FUVerticalAlignment = .top
    @State private var maxWidth: CGFloat = 300
    @State private var columns = 3
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: .leading, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView(.vertical) {
                    VMasonry(alignment: alignment, columns: columns, maxWidth: maxWidth) {
                        ForEach(items) { item in
                            Color.blue
                                .aspectRatio(item.value, contentMode: .fit)
                                .overlay(
                                    Text(String(item.value))
                                        .foregroundColor(.white)
                                )
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
                .animation(.default, value: verticalAlignment)
                .animation(.default, value: layoutDirection)
            )
            .environment(\.layoutDirection, layoutDirection)
            
            VStack {
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append(Item(value: items.randomElement()?.value ?? 1.5)) }
                        .padding()
                }
                
                Picker("Vertical Alignment", selection: $verticalAlignment) {
                    ForEach(FUVerticalAlignment.allCases) {
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
        .navigationTitle("VMasonry Aspect Ratio")
    }
}

struct VMasonryAspectRatioExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VMasonryAspectRatioExample()
        }
    }
}
#endif
