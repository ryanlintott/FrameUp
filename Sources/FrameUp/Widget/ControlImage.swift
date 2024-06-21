//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2024-06-19.
//

import SwiftUI

/// An image that will scale correctly and work inside a `ControlWidget`
///
/// Use inside a Label's icon property.
///
/// ```swift
/// Label {
///     Text("Label Text")
/// } icon: {
///     ControlImage("myImage")
/// }
/// ```
///
@available(iOS 18.0, *)
public struct ControlImage: View {
    let uiImage: UIImage
    
    /// Creates a SwiftUI `Image` that will scale correctly and work inside a `ControlWidget`
    public init(_ uiImage: UIImage) {
        self.uiImage = uiImage
    }
    
    public var body: Image {
        Image(uiImage: uiImage)
    }
}

@available(iOS 18.0, *)
public extension ControlImage {
    /// Creates a SwiftUI `Image` that will scale correctly and work inside a `ControlWidget`
    /// - Parameter name: The name of the image asset or file.
    /// - Parameter bundle: The bundle containing the image file or asset catalog. Specify nil to search the app’s main bundle.
    init?(_ name: String, bundle: Bundle? = nil) {
        guard let uiImage = UIImage(named: name, in: bundle, with: nil) else { return nil }
        self.init(uiImage)
    }
}
