//
//  AnyFULayoutSimpleExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-09-14.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct AnyFULayoutSimple: View {
    let isVStack: Bool
    let maxSize: CGSize
    
    var layout: any FULayout {
        isVStack ? VStackFULayout(maxWidth: maxSize.width) : HStackFULayout(maxHeight: maxSize.height)
    }
    
    var body: some View {
        AnyFULayout(layout) {
            Text("First")
            Text("Second")
            Text("Third")
        }
        .foregroundColor(.white)
        .padding()
        .background(Color.blue)
        .animation(.spring(), value: isVStack)
    }
}

struct AnyFULayoutSimpleExample: View {
    @State private var isVStack: Bool = true
    
    var body: some View {
        VStack {
            GeometryReader { proxy in
                Color.clear.overlay(
                    AnyFULayoutSimple(isVStack: isVStack, maxSize: proxy.size)
                )
            }
            
            VStack {
                Text("AnyFULayout can animate between layouts keeping view ids.")
                
                Toggle("Use VStack", isOn: $isVStack)
            }
            .padding()
        }
        .navigationTitle("AnyFULayout Simple")
    }
}

struct AnyFULayoutSimpleExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnyFULayoutSimpleExample()
        }
    }
}
#endif
