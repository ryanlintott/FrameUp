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
    @State private var width: CGFloat = 200
    
    var body: some View {
        VStack {
            Spacer()
            Text("Above")
            
            FULayoutThatFits(maxWidth: width, layouts: [HStackFULayout(maxHeight: 1000), VStackFULayout(maxWidth: width)]) {
                Color.green.frame(width: 50, height: 50)
                Color.yellow.frame(width: 50, height: 200)
                Color.blue.frame(width: 50, height: 100)
            }
            .animation(.default, value: width)
            .frame(width: width)
            .border(Color.red)
            
            Text("Below")
            
            Spacer()
            
            VStack {
                
                HStack {
                    #if os(tvOS)
                    Text("Width \(width)")
                    Button("-") { width = max(50, width - 50) }
                    Button("+") { width = min(350, width + 50) }
                    #else
                    Text("Width")
                    Slider(value: $width, in: 50...350)
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
