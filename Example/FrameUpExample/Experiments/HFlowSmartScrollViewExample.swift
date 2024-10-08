//
//  HFlowSmartScrollViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-10-20.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct HFlowSmartScrollViewExample: View {
    @State private var items = ["These", "Items", "can be arranged", "into any", "layout", "you like", "with", "FrameUp"]
        .map { Item(id: UUID(), value: $0) }
    
    @State private var optionalScrolling = false
    @State private var shrinkToFit = false
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    @State private var verticalAlignment: FUVerticalAlignment = .top
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear
                .overlay(
                    WidthReader { width in
                        SmartScrollView(.vertical, optionalScrolling: optionalScrolling, shrinkToFit: shrinkToFit) {
                            HFlow(alignment: alignment, maxWidth: width) {
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
                        }
                    }
                        .animation(.default, value: items)
                        .animation(.default, value: alignment)
                        .padding()
                )
            
            Spacer()
            
            VStack {
                HStack {
                    Button("Remove Item") { if !items.isEmpty { items.removeLast() } }
                        .padding()
                    Button("Add Item") { items.append(Item(value: items.randomElement()?.value ?? "New Item")) }
                        .padding()
                }
                
                Toggle(isOn: $optionalScrolling) {
                    Text("Optional Scrolling")
                }
                Toggle(isOn: $shrinkToFit) {
                    Text("Shrink to Fit")
                }
                
                Picker("Vertical Alignment", selection: $verticalAlignment) {
                    ForEach(FUVerticalAlignment.allCases) {
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
            }
            .padding()
        }
        .padding(.top, 1)
        .navigationTitle("HFlow")
    }
}

struct HFlowSmartScrollViewExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HFlowSmartScrollViewExample()
        }
    }
}
#endif
