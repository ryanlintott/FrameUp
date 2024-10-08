//
//  FittedVStack.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-05-22.
//

import SwiftUI

/**
 A `Layout` that arranges views like a `VStack` but it ensures the overall width is never larger than the proposed width. This is only used inside ``WidthReader``.

 Example:
 ```swift
 FittedVStack {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
struct FittedVStack: Layout, Sendable {
    let alignment: FUHorizontalAlignment
    let spacing: CGFloat
    
    init(alignment: FUHorizontalAlignment = .center, spacing: CGFloat = 0) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = AnyLayout(VStackLayout(alignment: alignment.alignment, spacing: spacing))
        var cache = layout.makeCache(subviews: subviews)
        
        let layoutSize = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        /// The layout width will match the VStack layout size but the width will not exceed the proposal
        let width = min(
            layoutSize.width,
            proposal.replacingUnspecifiedDimensions(by: layoutSize).width
        )
        
        return .init(width: width, height: layoutSize.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = AnyLayout(VStackLayout(alignment: alignment.alignment, spacing: spacing))
        var cache = layout.makeCache(subviews: subviews)
        
        let layoutSize = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        /// Adjust the origin based on the alignment.
        let alignmentAdjustment: CGFloat = switch alignment {
        case .leading, .justified: 0
        case .center: 0.5
        case .trailing: 1
        }
        
        let originX = bounds.origin.x + ((bounds.width - layoutSize.width) * alignmentAdjustment)
        let origin = CGPoint(x: originX, y: bounds.origin.y)
        
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
        FittedVStack(alignment: .center) {
            GeometryReader { proxy in
                Color.red.overlay(Text("\(proxy.size.width)"))
                
            }
            
            Color.red
                .frame(width: 400)
        }
        .background(Color.blue)
        .padding()
//    }
}
