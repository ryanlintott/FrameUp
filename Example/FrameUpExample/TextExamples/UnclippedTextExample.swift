//
//  UnclippedTextExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-09-20.
//

import FrameUp
import SwiftUI

/// This check ensures this code only builds in Xcode 16+
#if compiler(>=6)
@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
struct UnclippedTextExample: View {
    var body: some View {
        ScrollView {
            Grid {
                
                Text("Zapfino")
                    .font(.custom("zapfino", size: 18))
                    .unclippedTextRenderer()
                    .fixedSize()
                    .padding()
                
                GridRow {
                    Text("SwiftUI\nText")
                    
                    Text(".unclippedTextRenderer()")
                }
                .font(.caption)
                
                GridRow {
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
                
                Text("System serif black italic")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .padding()
                
                GridRow {
                    Text("SwiftUI\nText")
                    
                    Text(".unclippedTextRenderer()")
                }
                .font(.caption)
                
                GridRow {
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
        .navigationTitle("unclippedTextRenderer")
    }
}

@available(iOS 18, macOS 15, watchOS 11, tvOS 18, visionOS 2, *)
#Preview {
    UnclippedTextExample()
}
#endif
