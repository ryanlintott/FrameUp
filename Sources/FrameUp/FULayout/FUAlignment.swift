//
//  FUAlignment.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-10-19.
//

import SwiftUI

/// A alignment type used for FULayout that has a limited number of cases
public enum FUAlignment: String, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case topLeading
    case top
    case topTrailing
    case topJustified
    case leading
    case center
    case trailing
    case centerJustified
    case bottomLeading
    case bottom
    case bottomTrailing
    case bottomJustified
    case justifiedLeading
    case justifiedCenter
    case justifiedTrailing
    case justified
    
    public var id: Self { self }
    
    public init(horizontal: FUHorizontalAlignment, vertical: FUVerticalAlignment) {
        switch (vertical, horizontal) {
        case (.top, .leading): self = .topLeading
        case (.top, .center): self = .top
        case (.top, .trailing): self = .topTrailing
        case (.top, .justified): self = .topJustified
        case (.center, .leading): self = .leading
        case (.center, .center): self = .center
        case (.center, .trailing): self = .trailing
        case (.center, .justified): self = .centerJustified
        case (.bottom, .leading): self = .bottomLeading
        case (.bottom, .center): self = .bottom
        case (.bottom, .trailing): self = .bottomTrailing
        case (.bottom, .justified): self = .bottomJustified
        case (.justified, .leading): self = .justifiedLeading
        case (.justified, .center): self = .justifiedCenter
        case (.justified, .trailing): self = .justifiedTrailing
        case (.justified, .justified): self = .justified
        }
    }
    
    public var horizontal: FUHorizontalAlignment {
        switch self {
        case .topLeading, .leading, .bottomLeading, .justifiedLeading:
            return .leading
        case .top, .center, .bottom, .justifiedCenter:
            return .center
        case .topTrailing, .trailing, .bottomTrailing, .justifiedTrailing:
            return .trailing
        case .topJustified, .centerJustified, .bottomJustified, .justified:
            return .justified
        }
    }
    
    public var vertical: FUVerticalAlignment {
        switch self {
        case .topLeading, .top, .topTrailing, .topJustified:
            return .top
        case .leading, .center, .trailing, .centerJustified:
            return .center
        case .bottomLeading, .bottom, .bottomTrailing, .bottomJustified:
            return .bottom
        case .justifiedLeading, .justifiedCenter, .justifiedTrailing, .justified:
            return .justified
        }
    }
    
    public var alignment: Alignment {
        .init(horizontal: horizontal.alignment, vertical: vertical.alignment)
    }
    
    public func replacingVerticalJustification(with alternateAlignment: FUVerticalAlignment = .top) -> Self {
        .init(horizontal: self.horizontal, vertical: self.vertical.replacingJustification(with: alternateAlignment))
    }
    
    public func replacingHorizontalJustification(with alternateAlignment: FUHorizontalAlignment = .leading) -> Self {
        .init(horizontal: self.horizontal.replacingJustification(with: alternateAlignment), vertical: self.vertical)
    }
    
    /// Creates `FUAlignment` from `Alignment` for cases `.topLeading`, `.top`,  `.topTrailing`,  `.leading`,  `.center`,  `.trailing`,  `.bottomLeading`,  `.bottom`,  and `.bottomTrailing` and returns nil for all other cases.
    public init?(from alignment: Alignment) {
        switch alignment {
        case .topLeading: self = .topLeading
        case .top: self = .top
        case .topTrailing: self = .topTrailing
        case .leading: self = .leading
        case .center: self = .center
        case .trailing: self = .trailing
        case .bottomLeading: self = .bottomLeading
        case .bottom: self = .bottom
        case .bottomTrailing: self = .bottomTrailing
        default: return nil
        }
    }
}

public enum FUHorizontalAlignment: String, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case leading
    case center
    case trailing
    case justified
    
    public var id: Self { self }
    
    public var alignment: HorizontalAlignment {
        switch self {
        case .leading, .justified: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    public func replacingJustification(with alternateAlignment: Self = .leading) -> Self {
        switch self {
        case .justified:
            return alternateAlignment
        default:
            return self
        }
    }
    
    /// Creates `FUHorizontalAlignment` from `HoriztonalAlignment` for cases `.leading`, `.center`, and `.trailing` and returns nil for all other cases.
    public init?(_ horizontalAlignment: HorizontalAlignment) {
        switch horizontalAlignment {
        case .leading: self = .leading
        case .center: self = .center
        case .trailing: self = .trailing
        default: return nil
        }
    }
}

public enum FUVerticalAlignment: String, CaseIterable, Identifiable, Equatable, Hashable, Sendable {
    case top
    case center
    case bottom
    case justified
    
    public var id: Self { self }
    
    public var alignment: VerticalAlignment {
        switch self {
        case .top, .justified: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }
    
    public func replacingJustification(with alternateAlignment: Self = .top) -> Self {
        switch self {
        case .justified:
            return alternateAlignment
        default:
            return self
        }
    }
    
    /// Creates `FUVerticalAlignment` from `VerticalAlignment` for cases `.top`, `.center`, and `.bottom` and returns nil for all other cases.
    public init?(_ verticalAlignment: VerticalAlignment) {
        switch verticalAlignment {
        case .top: self = .top
        case .center: self = .center
        case .bottom: self = .bottom
        default: return nil
        }
    }
}
