//
//  RelativePaddingViewModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-01-30.
//

import SwiftUI

struct RelativePaddingViewModifier: ViewModifier {
    let edges: Edge.Set
    let lengthFactor: CGFloat
    
    @State private var size: CGSize? = nil
    
    /// A view modifier that pads its content by the specified edge insets with a percentage of the size.
    /// - Parameters:
    ///   - edges: The set of edges along which to pad this view. The default is .all.
    ///   - lengthFactor: The amount to inset this view as a fraction of the view size on the specified edges. Width is used for .leading/.trailing and height is used for .top/.bottom.
    init(edges: Edge.Set, lengthFactor: CGFloat) {
        self.edges = edges
        self.lengthFactor = lengthFactor
    }
    
    var verticalPadding: CGFloat {
        guard let height = size?.height else {
            return 0
        }
        return height * lengthFactor
    }
    
    var horizontalPadding: CGFloat {
        guard let width = size?.width else {
            return 0
        }
        return width * lengthFactor
    }
    
    var insets: EdgeInsets {
        EdgeInsets(
            top: edges.contains(.top) ? verticalPadding : 0,
            leading: edges.contains(.leading) ? horizontalPadding : 0,
            bottom: edges.contains(.bottom) ? verticalPadding : 0,
            trailing: edges.contains(.trailing) ? horizontalPadding : 0
        )
    }
    
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .onSizeChange { size in
                self.size = size
            }
    }
}

public extension View {
    /// Adds a padding amount to specified edges of this view relative to the size of the view.
    /// - Parameters:
    ///   - edges: The set of edges along which to pad this view. The default is .all.
    ///   - lengthFactor: The amount to inset this view as a fraction of the view size on the specified edges. Width is used for .leading/.trailing and height is used for .top/.bottom.
    /// - Returns: A view that's padded on specified edges by the relative amount specified.
    func relativePadding(_ edges: Edge.Set = .all, _ lengthFactor: CGFloat) -> some View {
        self.modifier(RelativePaddingViewModifier(edges: edges, lengthFactor: lengthFactor))
    }
    
    /// Adds a padding amount to this view relative to the size of the view.
    /// - Parameters:
    ///   - lengthFactor: The amount to inset this view as a fraction of the view size on the specified edges. Width is used for .leading/.trailing and height is used for .top/.bottom.
    /// - Returns: A view that's padded on all edges by the relative amount specified.
    func relativePadding(_ lengthFactor: CGFloat) -> some View {
        self.modifier(RelativePaddingViewModifier(edges: .all, lengthFactor: lengthFactor))
    }
}

struct RelativePaddingViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello World")
            .background(Color.red)
            .relativePadding(.top, -0.5)
            .relativePadding(.leading, -0.1)
            .overlay(Color.blue.opacity(0.5))
    }
}
