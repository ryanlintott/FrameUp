//
//  VStackFULayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-12.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct VStackFULayoutExample: View {
    @State private var items: [Item] = .examples
    @State private var horizontalAlignment: FUHorizontalAlignment = .center
    @State private var width: CGFloat = 300
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var body: some View {
        VStack {
            Text("Similar to VStack but will always grow vertically")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            Color.clear.overlay(
                ScrollView(.vertical) {
                    VStackFULayout(alignment: horizontalAlignment, maxWidth: width) {
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
                    .frame(width: width)
                    .padding()
                }
                .animation(.default, value: items)
                .animation(.default, value: width)
                .animation(.default, value: horizontalAlignment)
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

                Picker("Horizontal Alignment", selection: $horizontalAlignment) {
                    ForEach([FUHorizontalAlignment.leading, .center, .trailing]) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                #if os(tvOS)
                HStack {
                    Text("Width \(width, specifier: "%.0F")")
                    Button("-") { width = max(50, width - 50) }
                    Button("+") { width = min(600, width + 50) }
                }
                #else
                Stepper("Width \(width, specifier: "%.0F")", value: $width, in: 50...600, step: 50)
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
        .navigationTitle("VStackFULayout")
    }
}

struct VStackFULayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStackFULayoutExample()
        }
    }
}
#endif
