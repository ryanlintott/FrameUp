//
//  TagViewForScrollViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-15.
//

import FrameUp
import SwiftUI

@available(swift, deprecated: 6.0, message: "This view may crash with Swift 6 strict concurrency due to unsafe thread jumping. Use HFlowLayout instead.")
struct TagViewForScrollViewExample: View {
    let elements = ["Thing", "Another", "Test", "Short", "Long Text is Long", "More", "Cool Tag"]
    
    var body: some View {
        ScrollView {
            WidthReader { width in
                Text("Some text")
                
                TagViewForScrollView(maxWidth: width, elements: elements) { element in
                    Text(element)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .padding(2)
                }
                .padding(2)
                .background(Color.gray)
                
                Text("Some more text")
            }
        }
        .navigationTitle("TagViewForScroll")
    }
}

@available(swift, deprecated: 6.0, message: "This view may crash with Swift 6 strict concurrency due to unsafe thread jumping. Use HFlowLayout instead.")
struct TagViewForScrollViewExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TagViewForScrollViewExample()
        }
    }
}
