//
//  FittedHStack.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-05-30.
//

import SwiftUI

/**
 A `Layout` that arranges views like an `HStack` but it ensures the overall height is never larger than the proposed height. This is only used inside `HeightReader`.

 Example:
 ```swift
 FittedHStack {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
struct FittedHStack: Layout, Sendable {
    let alignment: FUVerticalAlignment
    let spacing: CGFloat
    
    init(alignment: FUVerticalAlignment = .center, spacing: CGFloat = 0) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = AnyLayout(HStackLayout(alignment: alignment.alignment, spacing: spacing))
        var cache = layout.makeCache(subviews: subviews)
        
        let layoutSize = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        /// The layout height will match the HStack layout size but the height will not exceed the proposal
        let height = min(
            layoutSize.height,
            proposal.replacingUnspecifiedDimensions(by: layoutSize).height
        )
        
        return .init(width: layoutSize.width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = AnyLayout(HStackLayout(alignment: alignment.alignment, spacing: spacing))
        var cache = layout.makeCache(subviews: subviews)
        
        let layoutSize = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        /// Adjust the origin based on the alignment.
        let alignmentAdjustment: CGFloat = switch alignment {
        case .top, .justified: 0
        case .center: 0.5
        case .bottom: 1
        }
        
        let originY = bounds.origin.y + ((bounds.height - layoutSize.height) * alignmentAdjustment)
        let origin = CGPoint(x: bounds.origin.x, y: originY)
        
        layout.placeSubviews(
            in: .init(origin: origin, size: bounds.size),
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
#Preview {
//    ScrollView {
        FittedHStack(alignment: .center) {
            GeometryReader { proxy in
                Color.red.overlay(Text("\(proxy.size.width)"))
                
            }
            
            Color.red
                .frame(height: 400)
        }
        .background(Color.blue)
        .padding()
//    }
}
