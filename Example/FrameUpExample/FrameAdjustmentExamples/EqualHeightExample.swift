//
//  EqualHeightExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-06-03.
//

import FrameUp
import SwiftUI

struct EqualHeightExample: View {
    @State private var height: CGFloat = 120
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("Views with `.equalHeightPreferred()` inside a view with `.equalHeightContainer()` will have heights equal to the largest view.")
                    
                    HStack {
                        Button { } label: {
                            Label("Info", systemImage: "info.circle")
                                .font(.title)
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Button { } label: {
                            Text("Cancel")
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Button { } label: {
                            Text("OK")
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                    }
                    .equalHeightContainer()
                    .padding(4)
                    .frame(height: height)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                    
                    Text("If space is limited views will shrink equally, each to a minimum size that fits the content.")
                    
                    VStack {
                        Button { } label: {
                            Label("Info", systemImage: "info.circle")
                                .font(.title)
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Spacer(minLength: 4)
                        
                        Button { } label: {
                            Text("Cancel")
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                        
                        Spacer(minLength: 4)
                        
                        Button { } label: {
                            Text("OK")
                                .equalHeightPreferred()
                                .padding(4)
                                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                        }
                    }
                    .equalHeightContainer()
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    
                    if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                        Text("It even works with custom layouts like VFlowLayout.")
                        
                        VFlowLayout {
                            Button { } label: {
                                Label("Info", systemImage: "info.circle")
                                    .font(.title)
                                    .equalHeightPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                            
                            Button { } label: {
                                Text("Cancel")
                                    .equalHeightPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                            
                            Button { } label: {
                                Text("OK")
                                    .equalHeightPreferred()
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.red))
                            }
                        }
                        .equalHeightContainer()
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                        .frame(height: height)
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            HStack {
                #if os(tvOS)
                Text("Height \(height)")
                Button("-") { height = max(30, height - 10) }
                Button("+") { height = min(200, height + 10) }
                #else
                Text("Height")
                Slider(value: $height, in: 30...200)
                #endif
            }
            .padding(.horizontal)
        }
        
        .padding()
        .navigationTitle("EqualHeight")
    }
}

#Preview {
    NavigationView {
        EqualHeightExample()
    }
}
