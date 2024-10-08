//
//  CustomFULayoutExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-09-15.
//

import FrameUp
import SwiftUI

struct PingPong: FULayout {
    let maxWidth: CGFloat
    
    let fixedSize: Axis.Set = .horizontal
    var maxItemWidth: CGFloat? { maxWidth }
    let maxItemHeight: CGFloat? = nil
    
    init(maxWidth: CGFloat) {
        self.maxWidth = maxWidth
    }
    
    func contentOffsets(sizes: [Int : CGSize]) -> [Int : CGPoint] {
        var widthOffset = 0.0
        var heightOffset = 0.0
        var leftToRight = true
        var offsets = [Int : CGPoint]()
        for size in sizes.sortedByKey() {
            if leftToRight {
                if widthOffset + size.value.width > maxWidth {
                    leftToRight = false
                    widthOffset = maxWidth - size.value.width
                }
            } else {
                if widthOffset > size.value.width {
                    widthOffset -= size.value.width
                } else {
                    leftToRight = true
                    widthOffset = .zero
                }
            }
            offsets.updateValue(
                CGPoint(x: widthOffset, y: heightOffset),
                forKey: size.key
            )
            if leftToRight {
                widthOffset += size.value.width
            }
            
            heightOffset += size.value.height
        }
        
        return offsets
    }
}

#if !os(visionOS)
struct CustomFULayoutExample: View {
    var body: some View {
        VStack {
            WidthReader { width in
                PingPong(maxWidth: width) {
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
            }
            
            Text("Create your own custom layouts like this one using the FULayout protocol.")
                .padding()
        }
        .navigationTitle("Custom FULayout")
    }
}

struct CustomFULayoutExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CustomFULayoutExample()
        }
    }
}
#endif
