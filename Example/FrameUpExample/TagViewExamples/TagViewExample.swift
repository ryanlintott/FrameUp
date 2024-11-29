//
//  TagViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-15.
//

import FrameUp
import SwiftUI

@available(swift, deprecated: 6)
struct TagViewExample: View {
    static let exampleItems = ["Thing", "Another", "Test", "Short", "Long Text is Long", "More", "Cool Tag"]
    @State private var items = Self.exampleItems
    @State private var layoutDirection: LayoutDirection = .leftToRight
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                TagView(elements: items) { element in
                    Text(element)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .padding(2)
                }
                    .padding(2)
                    .background(Color.gray)
                    .navigationTitle("TagView")
                .animation(.default, value: items)
                .animation(.default, value: layoutDirection)
            )
            .environment(\.layoutDirection, layoutDirection)
            
            VStack {
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append("\(items.randomElement() ?? Self.exampleItems.randomElement()!)\(Int.random(in: 1...100))") }
                        .padding()
                }
                
                Picker("Layout Direction", selection: $layoutDirection) {
                    ForEach(LayoutDirection.allCases, id: \.self) { direction in
                        Text(direction == .leftToRight ? "Left to Right" : "Right to Left")
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .navigationTitle("TagView")
    }
}

@available(swift, deprecated: 6)
struct TagViewExample_Previews: PreviewProvider {
    static var previews: some View {
        TagViewExample()
    }
}
