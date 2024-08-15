//
//  TextClipPadding.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-07-08.
//

import SwiftUI

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
struct TextClipPaddingTextRenderer: TextRenderer {
    let padding: EdgeInsets
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
    }
    
    func sizeThatFits(proposal: ProposedViewSize, text: TextProxy) -> CGSize {
        let textSize = text.sizeThatFits(proposal)
        return .init(width: textSize.width + padding.leading + padding.trailing, height: textSize.height + padding.top + padding.bottom)
    }
    
    var displayPadding: EdgeInsets {
        -padding
    }
}

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
public extension Text {
    /// Adds a different padding amount to each edge of a Text clipping frame.
    ///
    /// This modifier uses a text renderer to adjust the clipping frame and is intended to be used in situations where a font is rendering in a clipped frame. This will not increase the view padding.
    /// - Parameter insets: An EdgeInsets instance that contains padding amounts for each edge.
    /// - Returns: A view where the Text clipping frame is padded by different amounts on each edge.
    nonisolated func textClipPadding(_ insets: EdgeInsets) -> some View {
        textRenderer(TextClipPaddingTextRenderer(padding: insets))
            .padding(-insets)
    }
    
    /// Adds an equal padding amount to specific edges of a Text clipping frame.
    ///
    /// This modifier uses a text renderer to adjust the clipping frame and is intended to be used in situations where a font is rendering in a clipped frame. This will not increase the view padding.
    /// - Parameters:
    ///   - edges: The set of edges to pad for this Text clipping frame. The default is all.
    ///   - length: An amount, given in points, to pad this text clipping frame on the specified edges.
    /// - Returns: A view where the Text clipping frame is padded by the specified amount on the specified edges.
    nonisolated func textClipPadding(_ edges: Edge.Set = .all, _ length: CGFloat) -> some View {
        textClipPadding(
            EdgeInsets(
                top: edges.contains(.top) ? length : 0,
                leading: edges.contains(.leading) ? length : 0,
                bottom: edges.contains(.bottom) ? length : 0,
                trailing: edges.contains(.trailing) ? length : 0
            )
        )
    }
}

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
#Preview {
    Grid {
        GridRow {
            Text("")
            
            Text("SwiftUI\nText")
            
            Text("NoClip\nTextRenderer")
        }
        .font(.caption)
        
        GridRow {
            Text("Zapfino")
                .font(.custom("zapfino", size: 18))
                .textClipPadding(.all, 10)
                .fixedSize()
            
            Text("f")
                .font(.custom("zapfino", size: 30))
                .border(Color.red)
                .frame(maxWidth: .infinity)
            
            Text("f")
                .font(.custom("zapfino", size: 30))
                .textClipPadding(.all, 50)
                .border(Color.red)
                .frame(maxWidth: .infinity)
            
        }
        
        GridRow {
            Text("System serif black italic")
                .font(.system(size: 20, weight: .black, design: .serif))
            
            Text("f")
                .font(.system(size: 70, weight: .black, design: .serif))
                .italic()
                .border(Color.red)
            
            Text("f")
                .font(.system(size: 70, weight: .black, design: .serif))
                .italic()
                .textClipPadding(.all, 20)
                .border(Color.red)
            
        }
    }
    .multilineTextAlignment(.center)
    .padding()
}
