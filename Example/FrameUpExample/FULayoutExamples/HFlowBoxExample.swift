//
//  HFlowBoxExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-10-18.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct HFlowBoxExample: View {
    @State private var boxes = [1,2,3,4,5]
    @State private var horizontalAlignment: FUHorizontalAlignment = .leading
    let verticalAlignment: FUVerticalAlignment = .top
    
    var alignment: FUAlignment { .init(horizontal: horizontalAlignment, vertical: verticalAlignment)}
    
    var body: some View {
        VStack {
            Color.clear.overlay(
                ScrollView {
                    WidthReader { width in
                        HFlow(alignment: alignment, maxWidth: width) {
                            ForEach(boxes, id: \.self) { box in
                                Color.red
                                    .frame(width: 80, height: 80)
                                    .padding()
                            }
                        }
                    }
                }
                .animation(.default, value: boxes)
                .animation(.default, value: alignment)
            )
            
            VStack {
                HStack {
                    Button("Remove Box") { if !boxes.isEmpty { boxes.removeLast() } }
                        .padding()
                    Button("Add Box") { boxes.append((boxes.max() ?? 1) + 1) }
                        .padding()
                }
                
                Picker("Horizontal Alignment", selection: $horizontalAlignment) {
                    ForEach(FUHorizontalAlignment.allCases) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
        }
        .navigationTitle("HFlow Boxes")
    }
}

struct HFlowBoxExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HFlowBoxExample()
        }
    }
}
#endif
