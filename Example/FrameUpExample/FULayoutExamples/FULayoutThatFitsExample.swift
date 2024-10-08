//
//  FULayoutThatFitsExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-11-01.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct FULayoutThatFitsExample: View {
    @State private var maxWidth: CGFloat = 200
    
    var body: some View {
        VStack {
            Spacer()
            Text("Above")
            
            FULayoutThatFits(maxWidth: maxWidth, layouts: [HStackFULayout(maxHeight: 1000), VStackFULayout(maxWidth: maxWidth)]) {
                Color.green.frame(width: 50, height: 50)
                Color.yellow.frame(width: 50, height: 200)
                Color.blue.frame(width: 50, height: 100)
            }
            .animation(.default, value: maxWidth)
            .frame(width: maxWidth)
            .border(Color.red)
            
            Text("Below")
            
            Spacer()
            
            VStack {
                
                HStack {
                    #if os(tvOS)
                    Text("Max Width \(maxWidth)")
                    Button("-") { maxWidth = max(50, maxWidth - 50) }
                    Button("+") { maxWidth = min(350, maxWidth + 50) }
                    #else
                    Text("Max Width")
                    Slider(value: $maxWidth, in: 50...350)
                        .padding()
                    #endif
                }
            }
            .padding()
        }
        .navigationTitle("FULayoutThatFits")
    }
}

struct FULayoutThatFitsExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FULayoutThatFitsExample()
        }
    }
}
#endif
