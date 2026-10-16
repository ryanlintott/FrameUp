//
//  TopEdgesExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-16.
//

import FrameUp
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.abetterwaytodo.FrameUpExample", category: "TopEdges")

#if os(iOS)
/// A tab view whose top faces away from the system's vertical toolbar, so its tab bar sits beside the toolbar: on the iPhone Duo's outer screen, beside the column in every orientation, and on its inner screen, beside the column in landscape and along the bottom in portrait. On an iPhone that doesn't fold, the tab bar is along the bottom in portrait and away from the Dynamic Island in landscape.
///
/// The frame is fixed to the device, and the tab view turns inside it with the system's timing. A red strip runs along the tab view's top, and its tab bar is yellow; both reach out past the tab view to cover the gaps. A dashed line runs along its safe area. The information in the middle is in an `AutoRotatingView` of its own that allows every orientation, so it stays upright whichever way the tab view faces.
@available(iOS 17, *)
struct TopEdgesExample: View {
    @State private var isPresented: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The tab view's top, the red strip, faces away from the system's vertical toolbar, so its tab bar sits beside it. The dictionary is chosen for each screen and known before every turn. The frame around it stays fixed to the device. The red strip and the yellow tab bar reach past the tab view's edges to cover the screen during a turn.")
            
            Button("Show Tabs") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.callout)
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Top Edges")
        .fullScreenCover(isPresented: $isPresented) {
            TopEdgesProbe(isPresented: $isPresented)
        }
    }
}

/// Where the tab view's top points, as the user sees it, in each orientation.
/// The screens the example picks a dictionary for.
enum TopEdgesScreen {
    /// An iPhone that doesn't fold.
    case iPhone
    case foldableOuter
    case foldableInner
    /// The inner screen's left split window, where the column is on the left.
    case foldableInnerLeftWindow
    /// An iPad window of regular width, with the tab bar on its trailing edge.
    case iPadRegular
    /// An iPad window of compact width, with the tab bar along the bottom.
    case iPadCompact
    
    /// - Parameters:
    ///   - hingeScreen: The screen of a foldable iPhone, or nil on one that doesn't fold.
    ///   - systemBar: The system's bar, measured outside the rotation. Only a window change moves the column to the left, never a turn, so the dictionary changes then.
    ///   - horizontalSizeClass: The window's horizontal size class, which on an iPad changes only as the window is resized (measured: compact below about 665 points wide).
    init(hingeScreen: FUDeviceScreen?, systemBar: SystemBarGeometry?, horizontalSizeClass: UserInterfaceSizeClass?) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self = horizontalSizeClass == .compact ? .iPadCompact : .iPadRegular
            return
        }
        switch hingeScreen {
        case .outer: self = .foldableOuter
        case .inner: self = systemBar?.kind == .verticalToolbar && systemBar?.edge == .leading ? .foldableInnerLeftWindow : .foldableInner
        case nil: self = .iPhone
        }
    }
    
    /// Where the tab view's top points, as the user sees it, in each orientation: away from the system's vertical toolbar, measured in the iPhone Duo simulator (iOS 27.1). It has to be known before each turn, since the toolbar's new edge arrives after the turn has started.
    var topEdges: [FUInterfaceOrientation: Edge] {
        switch self {
        /// Held in device portrait, so the tab bar stays on the device's bottom edge, away from the Dynamic Island in landscape. The interface doesn't turn upside down, so that's left out.
        case .iPhone: [.portrait: .top, .landscapeRight: .trailing, .landscapeLeft: .leading]
        /// The tab view's top always points to the user's leading side, so its bottom, and the tab bar, is on the trailing edge, in every orientation.
        case .iPadRegular: [.portrait: .leading, .landscapeRight: .leading, .landscapeLeft: .leading, .portraitUpsideDown: .leading]
        /// Upright in every orientation, with the tab bar along the bottom.
        case .iPadCompact: [.portrait: .top, .landscapeRight: .top, .landscapeLeft: .top, .portraitUpsideDown: .top]
        /// The column is on the right in portrait and landscape right, and on the left in landscape left: it follows the camera in landscape. The interface doesn't turn upside down, so the column stays wherever the last orientation left it, and upside down is left out to keep the content with it.
        case .foldableOuter: [.portrait: .leading, .landscapeRight: .leading, .landscapeLeft: .trailing]
        /// The column is on the right in either landscape, and there's none in portrait, where the tab bar is along the bottom.
        case .foldableInner: [.portrait: .top, .landscapeRight: .leading, .landscapeLeft: .leading, .portraitUpsideDown: .top]
        /// The left split window's column is on the left in either landscape.
        case .foldableInnerLeftWindow: [.portrait: .top, .landscapeRight: .trailing, .landscapeLeft: .trailing, .portraitUpsideDown: .top]
        }
    }
    
    /// The orientations the views that stay upright turn to. The app doesn't support upside down, so they leave it out, except on a foldable iPhone's inner screen, where the system turns the interface to every orientation.
    var uprightOrientations: [FUInterfaceOrientation] {
        switch self {
        case .foldableInner, .foldableInnerLeftWindow: FUInterfaceOrientation.allCases
        case .iPhone, .foldableOuter: [.portrait, .landscapeLeft, .landscapeRight]
        case .iPadRegular, .iPadCompact: FUInterfaceOrientation.allCases
        }
    }
    
    /// The edge of the system's vertical toolbar the dictionary expects in an orientation, or nil for none: opposite where the tab view's top points.
    func expectedToolbarEdge(_ orientation: FUInterfaceOrientation) -> HorizontalEdge? {
        switch topEdges[orientation] {
        case .leading: .trailing
        case .trailing: .leading
        default: nil
        }
    }
}

/// The tab view in `AutoRotatingView(topEdges:)`, shown on launch with the `-FUTopEdgesScreen` launch argument for turning and folding the device without any navigation.
@available(iOS 17, *)
struct TopEdgesProbe: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        TopEdgesRotation(isPresented: $isPresented)
            /// Measured outside the rotation; the tab view reads it turned into its own frame.
            .measuresSystemBarGeometry()
            .sizeClassProbe()
    }
}

@available(iOS 17, *)
private struct TopEdgesRotation: View {
    @Binding var isPresented: Bool
    /// The screen of a foldable iPhone, or nil on one that doesn't fold.
    @State private var hingeScreen: FUDeviceScreen? = nil
    /// The system's bar outside the rotation.
    @Environment(\.systemBarGeometry) private var systemBar
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var screen: TopEdgesScreen {
        TopEdgesScreen(hingeScreen: hingeScreen, systemBar: systemBar, horizontalSizeClass: horizontalSizeClass)
    }
    
    var body: some View {
        AutoRotatingView(topEdges: screen.topEdges) {
            PresentedTabs(isPresented: $isPresented, screen: screen)
                .geometryProbe("inside")
        }
        .geometryProbe("outside")
        .toolbarEdgeCheck(screen)
        .onHingeScreenChange { hingeScreen = $0 }
    }
}

extension View {
    /// Logs whether the system's vertical toolbar, once it has settled, is where the screen's dictionary expects it.
    func toolbarEdgeCheck(_ screen: TopEdgesScreen) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85)
        return modifier(ToolbarEdgeCheck(screen: screen))
        #else
        return self
        #endif
    }
}

#if canImport(SwiftUICore, _version: 8.0.85)
private struct ToolbarEdgeCheck: ViewModifier {
    let screen: TopEdgesScreen
    
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.modifier(Reader(screen: screen))
        } else {
            content
        }
    }
    
    @available(iOS 27.1, *)
    private struct Reader: ViewModifier {
        let screen: TopEdgesScreen
        @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
        /// Changes with every turn of the device, so the check runs again even when nothing on the screen changes size, as between the two landscapes.
        @State private var deviceTurns = 0
        
        /// The interface's orientation, named as `AutoRotatingView` names it.
        var interfaceOrientation: FUInterfaceOrientation? {
            switch (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.effectiveGeometry.interfaceOrientation {
            case .portrait: .portrait
            case .portraitUpsideDown: .portraitUpsideDown
            case .landscapeLeft: .landscapeRight
            case .landscapeRight: .landscapeLeft
            default: nil
            }
        }
        
        /// The orientation as `AutoRotatingView` names it: the device's on the outer screen, and the interface's on the inner screen.
        var orientation: FUInterfaceOrientation? {
            if screen == .foldableInner {
                return interfaceOrientation
            }
            switch UIDevice.current.orientation {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            default: return nil
            }
        }
        
        func body(content: Content) -> some View {
            content
                                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                    deviceTurns += 1
                }
                .task(id: "\(toolbarVerticalEdge.map { "\($0)" } ?? "nil") \(screen) \(deviceTurns)") {
                    /// The edge and the orientation settle a moment after a turn or a fold.
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled, let orientation else { return }
                    /// iPads have no vertical toolbar, and place their bar themselves.
                    guard screen != .iPadRegular, screen != .iPadCompact else { return }
                    guard screen.topEdges[orientation] != nil else {
                        logger.info("toolbar check skipped screen \(String(describing: screen), privacy: .public) orientation \(String(describing: orientation), privacy: .public): not in the dictionary, so the content stays put")
                        return
                    }
                    let expected = screen.expectedToolbarEdge(orientation)
                    /// `toolbarVerticalEdge` names the interface's edge. Where the interface hasn't turned with the device, as when an iPhone is held upside down, the user sees it the other way round.
                    let isInterfaceUpsideDown = switch (interfaceOrientation, orientation) {
                    case (.portrait, .portraitUpsideDown), (.portraitUpsideDown, .portrait), (.landscapeLeft, .landscapeRight), (.landscapeRight, .landscapeLeft): true
                    default: false
                    }
                    let measured = isInterfaceUpsideDown ? toolbarVerticalEdge.map { $0 == .leading ? HorizontalEdge.trailing : .leading } : toolbarVerticalEdge
                    let result = expected == measured ? "ok" : "MISMATCH"
                    logger.info("toolbar check \(result, privacy: .public) screen \(String(describing: screen), privacy: .public) orientation \(String(describing: orientation), privacy: .public) expected \(expected.map { "\($0)" } ?? "nil", privacy: .public) measured \(measured.map { "\($0)" } ?? "nil", privacy: .public)")
                }
        }
    }
}
#endif

@available(iOS 17, *)
extension View {
    /// Shows and logs the window's size and size classes whenever they change, to see when resizing a window changes them.
    func sizeClassProbe() -> some View {
        modifier(SizeClassProbe())
    }
}

@available(iOS 17, *)
private struct SizeClassProbe: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var windowSize: CGSize = .zero
    
    var description: String {
        func name(_ sizeClass: UserInterfaceSizeClass?) -> String {
            switch sizeClass {
            case .compact: "C"
            case .regular: "R"
            default: "?"
            }
        }
        return "window \(Int(windowSize.width))x\(Int(windowSize.height)) size classes W \(name(horizontalSizeClass)) H \(name(verticalSizeClass))"
    }
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                /// The window, including its safe area.
                CGSize(width: proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing, height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom)
            } action: {
                windowSize = $0
            }
            .overlay(alignment: .top) {
                Text(description)
                    .font(.caption.monospaced())
                    .padding(6)
                    .background(.regularMaterial, in: .capsule)
                    .padding(.top, 4)
                    .allowsHitTesting(false)
            }
            .onChange(of: description, initial: true) {
                logger.info("size class probe \(description, privacy: .public)")
            }
    }
}

extension View {
    /// Logs the size, safe area, reserved regions and the system's vertical toolbar edge as this view sees them, whenever they change, to compare them inside and outside a rotation.
    func geometryProbe(_ label: String) -> some View {
        modifier(GeometryProbe(label: label))
    }
}

private struct GeometryProbe: ViewModifier {
    let label: String
    
    func body(content: Content) -> some View {
        /// `reservedRegions` and `toolbarVerticalEdge` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content.modifier(Reader(label: label))
        } else {
            content
        }
        #else
        content
        #endif
    }
    
    #if canImport(SwiftUICore, _version: 8.0.85)
    @available(iOS 27.1, *)
    private struct Reader: ViewModifier {
        let label: String
        @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
        @Environment(\.autoRotatingOrientation) private var orientation
        
        func body(content: Content) -> some View {
            let edge = toolbarVerticalEdge.map { "\($0)" } ?? "nil"
            let presented = orientation.map { "\($0)" } ?? "none"
            content
                .onGeometryChange(for: String.self) { proxy in
                    let occlusion = proxy.reservedRegions(kind: .occlusion).map { Self.text($0.frame) }
                    let division = proxy.reservedRegions(kind: .division, options: .includeInactive).map { Self.text($0.frame) }
                    let insets = proxy.safeAreaInsets
                    return "size \(Int(proxy.size.width))x\(Int(proxy.size.height)) safe t\(Int(insets.top)) l\(Int(insets.leading)) b\(Int(insets.bottom)) r\(Int(insets.trailing)) occlusion \(occlusion) division \(division)"
                } action: { geometry in
                    logger.info("probe \(label, privacy: .public) presented \(presented, privacy: .public) toolbarEdge \(edge, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) device \(UIDevice.current.orientation.rawValue, privacy: .public) \(geometry, privacy: .public)")
                }
                /// The environment can change without the geometry changing.
                .onChange(of: edge + " " + presented) {
                    logger.info("probe \(label, privacy: .public) presented \(presented, privacy: .public) toolbarEdge \(edge, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) (environment only)")
                }
        }
        
        static func text(_ rect: CGRect) -> String {
            "(\(Int(rect.minX)),\(Int(rect.minY)) \(Int(rect.width))x\(Int(rect.height)))"
        }
    }
    #endif
}

@available(iOS 17, *)
private struct PresentedTabs: View {
    @Binding var isPresented: Bool
    let screen: TopEdgesScreen
    /// The system's bar, turned into the tab view's frame. The tab view's top faces away from it, so it should always be on the bottom edge.
    @Environment(\.systemBarGeometry) private var systemBar
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var systemBarDescription: String {
        guard let systemBar else { return "nil" }
        return "\(systemBar.kind) edge \(systemBar.edge) depth \(Int(systemBar.depth)) usable \(Int(systemBar.usableStart))-\(Int(systemBar.usableEnd)) reserved \(Int(systemBar.reservedDepth))"
    }
    
    var body: some View {
        GeometryReader { proxy in
            tabs
                .task(id: systemBarDescription) {
                    /// Logged once the bar has settled after a turn or a fold.
                    try? await Task.sleep(for: .seconds(1))
                    /// An iPhone that doesn't fold places its bar along the tab view's bottom itself, not where the system's bar is.
                    guard !Task.isCancelled, screen != .iPhone, screen != .iPadRegular, screen != .iPadCompact else { return }
                    let result = systemBar?.edge == .bottom ? "ok" : "MISMATCH"
                    logger.info("system bar \(result, privacy: .public) inside \(systemBarDescription, privacy: .public) presented \(orientation.map { "\($0)" } ?? "none", privacy: .public)")
                }
                .onChange(of: orientation, initial: true) {
                    logger.info("presented \(orientation.map { "\($0)" } ?? "none", privacy: .public) size \(proxy.size.width, privacy: .public)x\(proxy.size.height, privacy: .public) scene \(FUInterfaceOrientationName.scene, privacy: .public) device \(UIDevice.current.orientation.rawValue, privacy: .public)")
                }
        }
    }
    
    @State private var tab = "book"
    
    var tabs: some View {
        TabView(selection: $tab) {
            ForEach(Self.items, id: \.tab) { item in
                /// The information turns to stay upright, whichever way the tab view faces, in the orientations the screen supports. Elsewhere it stays as it was.
                AutoRotatingView(screen.uprightOrientations) {
                    VStack(spacing: 12) {
                        Image(systemName: item.tab)
                            .font(.system(size: 60))
                        DeviceOrientationInfo(topEdges: screen.topEdges)
                        Button("Close") {
                            isPresented = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .border(.yellow, width: 2)
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(item.tab)
            }
        }
        .overlay {
            EdgeOutlines()
        }
        .modifier(TabBarPlacement(screen: screen, tab: $tab))
        .onChange(of: tab) {
            logger.info("selected \(tab, privacy: .public)")
        }
    }
    
    /// Titles as long as Wordhord's, to see whether a turned item fits its cell.
    static let items: [(tab: String, title: String)] = [
        ("book", "Wordhord"),
        ("building.columns", "Categories"),
        ("star", "Favourites"),
        ("scroll", "About")
    ]
}

/// The tab menu in the system's bar: spread along a bar at the bottom, and grouped at the user's bottom end of a vertical toolbar, as the system groups its own, with the items listed from the user's top or leading end.
@available(iOS 17, *)
/// Places the tab bar along the tab view's bottom.
///
/// On the iPhone Duo it goes where the system's bar is, which the tab view's top always faces away from. An iPhone that doesn't fold has no vertical toolbar, and its system bar is along the interface's bottom, which is the side of a tab view held in portrait. So there the bar goes along the tab view's own bottom instead, away from the Dynamic Island in landscape, as Wordhord does.
@available(iOS 17, *)
private struct TabBarPlacement: ViewModifier {
    let screen: TopEdgesScreen
    @Binding var tab: String
    @Environment(\.interfaceTurn) private var turn
    /// The tab view's safe area along its bottom, measured outside the bar's own inset.
    @State private var bottomSafeArea: CGFloat = 0
    
    /// How deep the bar is from the screen's edge: 50 points above the safe area when the tab view is upright, like the system's tab bar, and 84 points from the edge when it's held sideways, like a vertical toolbar, whose depth the turned items need for their titles.
    var barDepth: CGFloat {
        turn.isSideways ? 84 : 50 + bottomSafeArea
    }
    
    func body(content: Content) -> some View {
        switch screen {
        case .iPhone, .iPadRegular, .iPadCompact:
            content
                /// The content moves up only as far as the bar reaches past the safe area it already has.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear
                        .frame(height: max(0, barDepth - bottomSafeArea))
                }
                .overlay(alignment: .bottom) {
                    SystemBarTabs(edge: .bottom, isGrouped: false, usableStart: 0, usableEnd: 0, tab: $tab, orientations: screen.uprightOrientations)
                        .frame(height: barDepth)
                        .ignoresSafeArea(edges: .bottom)
                }
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: {
                    bottomSafeArea = $0
                }
        case .foldableOuter, .foldableInner, .foldableInnerLeftWindow:
            content
                .systemBarInset { bar in
                    SystemBarTabs(bar: bar, tab: $tab, orientations: screen.uprightOrientations)
                }
        }
    }
}

@available(iOS 17, *)
private struct SystemBarTabs: View {
    /// The edge of the tab view the bar is on.
    let edge: Edge
    /// True to group the items at the user's bottom end, as the system does in its vertical toolbar, rather than spreading them along the bar.
    let isGrouped: Bool
    /// How far the part of the bar free for items is from each end.
    let usableStart: CGFloat
    let usableEnd: CGFloat
    @Binding var tab: String
    let orientations: [FUInterfaceOrientation]
    @Environment(\.interfaceTurn) private var turn
    @Environment(\.layoutDirection) private var layoutDirection
    
    /// The length of each item's slot in the system's vertical toolbar: the system's natural item height, as FrameUp's own vertical bar uses.
    static let slotLength: CGFloat = 50
    /// How far the system keeps its grouped items from the window's bottom edge (measured on the iPhone Duo).
    static let groupMargin: CGFloat = 24
    /// How far the bar's colour reaches past the container.
    static let extent: CGFloat = 2000
    
    init(edge: Edge, isGrouped: Bool, usableStart: CGFloat, usableEnd: CGFloat, tab: Binding<String>, orientations: [FUInterfaceOrientation]) {
        self.edge = edge
        self.isGrouped = isGrouped
        self.usableStart = usableStart
        self.usableEnd = usableEnd
        self._tab = tab
        self.orientations = orientations
    }
    
    /// The tab menu in the system's bar.
    init(bar: SystemBarGeometry, tab: Binding<String>, orientations: [FUInterfaceOrientation]) {
        self.init(edge: bar.edge, isGrouped: bar.kind == .verticalToolbar, usableStart: bar.usableStart, usableEnd: bar.usableEnd, tab: tab, orientations: orientations)
    }
    
    /// True when the bar runs along this view's top or bottom.
    var isHorizontal: Bool {
        edge == .top || edge == .bottom
    }
    
    /// True when the bar's start, its leading or top end, isn't where the user starts reading: the top of the interface, or its leading end.
    var isReversed: Bool {
        let startSide = turn.interfaceEdge(of: isHorizontal ? .leading : .top, layoutDirection: layoutDirection)
        return startSide != .top && startSide != .leading
    }
    
    /// Where the items group in a vertical toolbar: the end of the bar at the bottom of the interface.
    var groupAlignment: Alignment {
        switch turn.localEdge(of: .bottom, layoutDirection: layoutDirection) {
        case .top: .top
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }
    
    /// Away from the container's edge, so the menu sits clear of the safe area the bar includes, such as the Home indicator.
    var innerAlignment: Alignment {
        switch edge {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
    
    var items: [TabMenuItem<String>] {
        let items = PresentedTabs.items.map { TabMenuItem(LocalizedStringKey($0.title), systemImage: $0.tab, tab: $0.tab) }
        return isReversed ? items.reversed() : items
    }
    
    var body: some View {
        /// A horizontal `TabMenu` pads each item 10 points either side, so a slot needs that much more length.
        let groupLength = (Self.slotLength + 20) * CGFloat(items.count)
        TabMenu(selection: $tab, items: items)
            .tabMenuItemStyle(UprightTabMenuItemStyle(orientations: orientations, base: .masked { isSelected in
                isSelected ? Color.accentColor : Color.secondary
            }))
            .onTabMenuItemReselect("Reselect") {
                logger.info("reselected \(tab, privacy: .public)")
            }
            /// The menu runs across the bar's full depth, which is each turned item's width when the bar is vertical to the user.
            .tabMenuFillsHeight(isGrouped || turn.isSideways)
            .frame(width: isGrouped && isHorizontal ? groupLength : nil, height: isGrouped && !isHorizontal ? groupLength : nil)
            .padding(Edge.Set(turn.localEdge(of: .bottom, layoutDirection: layoutDirection)), isGrouped ? Self.groupMargin : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isGrouped ? groupAlignment : innerAlignment)
            /// The part of the bar clear of the camera, the status items and the hinge.
            .padding(isHorizontal ? .leading : .top, usableStart)
            .padding(isHorizontal ? .trailing : .bottom, usableEnd)
            .background {
                /// Reaches far out past the container's edge and along it, like the red strip, so it covers anything behind the content during a turn.
                Color.yellow
                    .padding(Edge.Set(edge), -Self.extent)
                    .padding(isHorizontal ? .horizontal : .vertical, -Self.extent)
                    .allowsHitTesting(false)
            }
    }
}

/// Draws each item with another style, in an `AutoRotatingView` of its own, so it stays upright to the user whichever way the menu faces, in the orientations it allows.
private struct UprightTabMenuItemStyle<Base: TabMenuItemStyle>: TabMenuItemStyle {
    /// The orientations the item turns to.
    let orientations: [FUInterfaceOrientation]
    let base: Base
    
    func makeBody(configuration: Configuration) -> some View {
        AutoRotatingView(orientations) {
            base.makeBody(configuration: configuration)
        }
    }
}

/// The orientation of the device, read from the `AutoRotatingView` the information is in, which allows every orientation, and where the tab view's top points in it.
private struct DeviceOrientationInfo: View {
    let topEdges: [FUInterfaceOrientation: Edge]
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var body: some View {
        VStack(spacing: 4) {
            Text(orientation.map { "\($0)" } ?? "none")
                .font(.title2.monospaced())
            Text("up: \(orientation.flatMap { topEdges[$0] }.map { "\($0)" } ?? "none")")
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

/// A red strip along the top of the full area, reaching far out past it so it covers anything behind the content during a turn, and a dashed line along the safe area.
private struct EdgeOutlines: View {
    /// How far the strip reaches inside the full area.
    let thickness: CGFloat = 24
    /// How far the strip reaches out past the full area, along it and away from it.
    let extent: CGFloat = 2000
    
    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                Rectangle().fill(.red)
                    .frame(height: thickness + extent)
                    .padding(.horizontal, -extent)
                    .offset(y: -extent)
            }
            .ignoresSafeArea()
            .overlay {
                Rectangle()
                    .stroke(.primary, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            }
            .allowsHitTesting(false)
    }
}

@available(iOS 17, *)
private enum FUInterfaceOrientationName {
    @MainActor static var scene: String {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene.map { "\($0.effectiveGeometry.interfaceOrientation.rawValue)" } ?? "none"
    }
}

#Preview {
    if #available(iOS 17, *) {
        NavigationView {
            TopEdgesExample()
        }
    }
}
#endif
