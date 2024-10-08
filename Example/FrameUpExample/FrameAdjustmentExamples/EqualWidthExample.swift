//
//  EqualWidthExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-06-03.
//

import FrameUp
import SwiftUI

struct EqualWidthExample: View {
    @State private var width: CGFloat = 300
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("Views with `.equalWidthPreferred()` inside a view with `.equalWidthContainer()` will have widths equal to the largest view.")
                    
                    VStack {
                        Button { } label: {
                            Text("More Information")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Button { } label: {
                            Text("Cancel")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Button { } label: {
                            Text("OK")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                    }
                    .equalWidthContainer()
                    .padding(4)
                    .frame(width: width)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                    
                    Text("If space is limited views will shrink equally, each to a minimum size that fits the content.")
                    
                    HStack {
                        Button { } label: {
                            Text("More Information")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Spacer(minLength: 4)
                        
                        Button { } label: {
                            Text("Cancel")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Spacer(minLength: 4)
                        
                        Button { } label: {
                            Text("OK")
                                .equalWidthPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                    }
                    .equalWidthContainer()
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                    .frame(width: width)
                    .frame(maxWidth: .infinity)
                    
                    if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                        Text("It even works with custom layouts like HFlow.")
                        
                        HFlowLayout {
                            Button { } label: {
                                Text("More Information")
                                    .equalWidthPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                            
                            Button { } label: {
                                Text("Cancel")
                                    .equalWidthPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                            
                            Button { } label: {
                                Text("OK")
                                    .equalWidthPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                        }
                        .equalWidthContainer()
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                        .frame(width: width)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            HStack {
                #if os(tvOS)
                Text("Width \(width)")
                Button("-") { width = max(10, width - 10) }
                Button("+") { width = min(600, width + 10) }
                #else
                Text("Width")
                Slider(value: $width, in: 10...600)
                #endif
            }
            .padding(.horizontal)
        }
        
        .padding()
        .navigationTitle("EqualWidth")
    }
}

#Preview {
    NavigationView {
        EqualWidthExample()
    }
}
