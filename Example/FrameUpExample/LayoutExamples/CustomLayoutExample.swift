//
//  CustomLayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-18.
//

import FrameUp
import SwiftUI

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct PingPongLayout: LayoutFromFULayout {
    func fuLayout(maxSize: CGSize) -> PingPong {
        PingPong(maxWidth: maxSize.width)
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct CustomLayoutExample: View {
    var body: some View {
        VStack {
            PingPongLayout {
                Group {
                    Text("One")
                    Text("Two")
                    Text("Three")
                    Text("Four")
                    Text("Five")
                    Text("Six")
                    Text("Seven")
                    Text("Eight")
                    Text("Nine")
                    Text("Ten")
                }
                .font(.title)
                .foregroundColor(.white)
                .padding(5)
                .background(Color.blue.cornerRadius(5))
                .padding(2)
            }
            .frame(maxWidth: .infinity)
            
            Text("Easily create SwiftUI Layouts like this one from your own custom FULayout using the LayoutFromFULayout protocol.")
                .padding()
        }
        .navigationTitle("LayoutFromFULayout")
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
struct CustomLayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CustomLayoutExample()
        }
    }
}
