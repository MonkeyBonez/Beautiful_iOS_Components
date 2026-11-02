#if canImport(UIKit)
import OSLog
import SwiftUI
import UIKit

/// A liquid‑glass toast pill inspired by a water droplet hitting glass.
///
/// Design intent: it should feel like a droplet falls onto the screen, spreads outward,
/// then gently recoils the way water does after it lands or spills. The animation phases
/// map to that metaphor:
/// - `dropTime`: initial fade/drop‑in as the droplet arrives
/// - `expansionDuration` + `overshootPercent`: rapid spread with a soft overshoot
/// - `contractionDuration`: gentle recoil back toward equilibrium
/// - `holdDuration`: optional brief settle before disappearing
/// - `closeDuration`: smooth collapse/fade out
///
/// The surface uses a glass effect to sell the liquid aesthetic while keeping the text legible.
public struct LiquidGlassToast: View {
    public let message: String
    public var dropTime: TimeInterval = 1.2
    public var expansionDuration: TimeInterval = 0.5
    public var overshootPercent: CGFloat = 0.055
    public var contractionDuration: TimeInterval = 2.3
    public var holdDuration: TimeInterval? = 0.4
    public var closeDuration: TimeInterval = 0.35
    public var tapToClose: Bool = true
    public var useTint: Bool = true
    public var tintColor: Color?
    public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .soft
    public var onDismiss: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var measuredSize: CGSize = .zero
    @State private var currentWidth: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var outerOpacity: Double = 0
    @State private var hasPresented: Bool = false
    @State private var didDismiss: Bool = false
    @State private var isClosingRequested: Bool = false
    @State private var lastHapticMessage: String?

    public init(
        message: String,
        dropTime: TimeInterval = 1.2,
        expansionDuration: TimeInterval = 0.5,
        overshootPercent: CGFloat = 0.055,
        contractionDuration: TimeInterval = 2.3,
        holdDuration: TimeInterval? = 0.4,
        closeDuration: TimeInterval = 0.35,
        tapToClose: Bool = true,
        useTint: Bool = true,
        tintColor: Color? = nil,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .soft,
        onDismiss: (() -> Void)? = nil
    ) {
        self.message = message
        self.dropTime = dropTime
        self.expansionDuration = expansionDuration
        self.overshootPercent = overshootPercent
        self.contractionDuration = contractionDuration
        self.holdDuration = holdDuration
        self.closeDuration = closeDuration
        self.tapToClose = tapToClose
        self.useTint = useTint
        self.tintColor = tintColor
        self.hapticStyle = hapticStyle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        GeometryReader { container in
            ZStack {
                styledMessage
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { measuredSize = $0 }
                    .hidden()

                styledMessage
                    .frame(width: measuredSize.width, height: measuredSize.height)
                    .opacity(textOpacity)
                    .frame(width: min(max(currentWidth, 0), container.size.width))
                    .clipped()
                    .contentShape(toastShape)
                    .glassEffect(
                        useTint ? .regular.tint(tintColor ?? .clear) : .regular,
                        in: toastShape
                    )
                    .opacity(outerOpacity)
                    .onTapGesture {
                        guard tapToClose else { return }
                        isClosingRequested = true
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: max(measuredSize.height, 28))
        .opacity(message.isEmpty ? 0 : 1)
        .allowsHitTesting(!message.isEmpty && !didDismiss)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityHidden(message.isEmpty || didDismiss)
        .onChange(of: message) { _, _ in
            isClosingRequested = false
            didDismiss = false
            textOpacity = 0
            outerOpacity = 0
        }
        .task(id: AnimationKey(
            message: message,
            size: measuredSize,
            closing: isClosingRequested,
            reduceMotion: reduceMotion
        )) {
            await runPresentation()
        }
    }

    private var styledMessage: some View {
        Text(message)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var toastShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: min(max(measuredSize.height, 28) / 2, 32))
    }

    private func runPresentation() async {
        guard !didDismiss,
              !message.isEmpty || hasPresented,
              message.isEmpty || measuredSize.width > 0 else { return }
        do {
            if !message.isEmpty, !isClosingRequested {
                hasPresented = true
                try await open()
            }
            try await close()
            try Task.checkCancellation()
            didDismiss = true
            onDismiss?()
        } catch is CancellationError {
            return
        } catch {
            Logger(subsystem: "Beautiful_iOS_Components", category: "LiquidGlassToast")
                .error("Toast animation failed: \(error.localizedDescription)")
        }
    }

    private func open() async throws {
        let hold = max(0, holdDuration ?? 0)
        if reduceMotion {
            currentWidth = measuredSize.width
            textOpacity = 1
            outerOpacity = 1
            playHaptic()
            // Removing animation must not shorten the time available to read the message.
            try await pause(max(0, dropTime) + max(0, expansionDuration) + max(0, contractionDuration) + hold)
            return
        }
        currentWidth = max(measuredSize.height, 28)
        textOpacity = 0
        outerOpacity = 0
        withAnimation(.easeOut(duration: max(0, dropTime))) { outerOpacity = 1 }
        try await pause(dropTime)
        playHaptic()
        withAnimation(.easeOut(duration: max(0, expansionDuration))) {
            currentWidth = measuredSize.width * (1 + max(0, overshootPercent))
        }
        withAnimation(.easeIn(duration: max(0, expansionDuration))) { textOpacity = 1 }
        try await pause(expansionDuration)
        withAnimation(.easeOut(duration: max(0, contractionDuration))) {
            currentWidth = measuredSize.width
        }
        try await pause(max(0, contractionDuration) + hold)
    }

    private func close() async throws {
        if reduceMotion {
            textOpacity = 0
            currentWidth = 0
            outerOpacity = 0
            return
        }
        withAnimation(.smooth(duration: 0.2)) { textOpacity = 0 }
        try await pause(0.2)
        withAnimation(.smooth(duration: max(0, closeDuration))) {
            currentWidth = 0
            outerOpacity = 0
        }
        try await pause(closeDuration)
    }

    private func pause(_ duration: TimeInterval) async throws {
        try await Task.sleep(for: .seconds(max(0, duration)))
        try Task.checkCancellation()
    }

    private func playHaptic() {
        guard lastHapticMessage != message else { return }
        lastHapticMessage = message
        if let hapticStyle {
            UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred()
        }
    }

    private struct AnimationKey: Equatable {
        let message: String
        let size: CGSize
        let closing: Bool
        let reduceMotion: Bool
    }
}

#Preview("LiquidGlassToast") {
    ZStack(alignment: .top) {
        Color.black.opacity(0.05).ignoresSafeArea()
        LiquidGlassToast(message: "Liquid Glass Toast", useTint: true, tintColor: .blue.opacity(0.8))
            .padding(.top, 10)
    }
}
#endif
