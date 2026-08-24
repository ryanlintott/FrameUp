//
//  HStackFULayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-12.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct HStackFULayoutExample: View {
    @State private var items: [Item] = .examples
    @State private var verticalAlignment: FUVerticalAlignment = .center
    @State private var height: CGFloat = 300
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var body: some View {
        VStack {
            Text("Similar to HStack but will always grow horizontally")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Color.clear.overlay(
                ScrollView(.horizontal) {
                    HStackFULayout(alignment: verticalAlignment, maxHeight: height) {
                        ForEach(items) { item in
                            Text(item.value)
                                .padding(12)
                                .foregroundColor(.white)
                                .frame(height: CGFloat(item.value.count) * 6)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .geometryGroupIfAvailable()
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .border(Color.red)
                    .frame(height: height)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: height)
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

                #if os(tvOS)
                HStack {
                    Text("Height \(height, specifier: "%.0F")")
                    Button("-") { height = max(50, height - 50) }
                    Button("+") { height = min(600, height + 50) }
                }
                #else
                Stepper("Height \(height, specifier: "%.0F")", value: $height, in: 50...600, step: 50)
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
        .navigationTitle("HStackFULayout")
    }
}

struct HStackFULayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HStackFULayoutExample()
        }
    }
}
#endif
