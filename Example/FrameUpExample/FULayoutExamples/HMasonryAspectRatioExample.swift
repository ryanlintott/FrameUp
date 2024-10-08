//
//  HMasonryAspectRatioExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-11.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct HMasonryAspectRatioExample: View {
    @State private var items: [Item] = [1, 1.3, 1.4, 0.5, 0.7, 1.1, 2, 0.6].map { .init(value: $0) }
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var maxHeight: CGFloat = 300
    @State private var rows = 3
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: .top)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView(.horizontal) {
                    HMasonry(alignment: alignment, rows: rows, maxHeight: maxHeight) {
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
                    .frame(maxHeight: maxHeight, alignment: .top)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: rows)
                .animation(.default, value: maxHeight)
                .animation(.default, value: horizontalAlignment)
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

                Picker("Horizontal Alignment", selection: $horizontalAlignment) {
                    ForEach(FUHorizontalAlignment.allCases) {
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

                #if os(tvOS)
                HStack {
                    Text("Rows \(rows)")
                    Button("-") { rows = max(2, rows - 1) }
                    Button("+") { rows = min(6, rows + 1) }
                }
                #else
                Stepper("Rows \(rows)", value: $rows, in: 2...6)
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
        .navigationTitle("HMasonry Aspect Ratio")
    }
}

struct HMasonryAspectRatioExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HMasonryAspectRatioExample()
        }
    }
}
#endif
