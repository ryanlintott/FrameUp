//
//  UnclippedTextRenderer.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2024-07-08.
//

import SwiftUI

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
struct UnclippedTextRenderer: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
    }
    
    func sizeThatFits(proposal: ProposedViewSize, text: TextProxy) -> CGSize {
        text.sizeThatFits(proposal)
    }
}

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
public extension View {
    /// Adds a simple text renderer that draws the text without any changes. Using a text renderer will remove the clipping frame normally applied when rendering text. This modifier is unnecessary if another text renderer is already used.
    /// - Returns: A view where the Text clipping frame removed.
    nonisolated internal func unclippedTextRenderer() -> some View {
        textRenderer(UnclippedTextRenderer())
    }
}

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
#Preview {
    VStack {
        Text("fksdjfhaksdjfhkasdhfakjsdhfa")
            .font(.custom("zapfino", size: 24))
            .border(.red)
        
        Text("fksdjfhaksdjfhkasdhfakjsdhfa")
            .font(.custom("zapfino", size: 24))
            .unclippedTextRenderer()
            .border(.red)
    }
    .padding(30)
    
    Grid {
        GridRow {
            Text("")
            
            Text("SwiftUI\nText")
            
            Text(".unclipped()")
        }
        .font(.caption)
        
        GridRow {
            Text("Zapfino")
                .font(.custom("zapfino", size: 18))
                .unclippedTextRenderer()
                .fixedSize()
            
            Text("f")
                .font(.custom("zapfino", size: 30))
                .border(Color.red)
                .frame(maxWidth: .infinity)
            
            Text("f")
                .font(.custom("zapfino", size: 30))
                .unclippedTextRenderer()
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
                .unclippedTextRenderer()
                .border(Color.red)
            
        }
    }
    .multilineTextAlignment(.center)
    .padding()
}
