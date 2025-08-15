#if canImport(UIKit)
import SwiftUI
import UIKit

/// A liquid-glass style toast pill that animates in, expands with overshoot, holds, and dismisses.
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
	public var tintColor: Color? = nil
	public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .soft
	public var onDismiss: (() -> Void)? = nil
	
	@State private var measuredWidth: CGFloat = 0
	@State private var measuredHeight: CGFloat = 0
	@State private var currentWidth: CGFloat = 0
	@State private var textOpacity: Double = 0
	@State private var outerOpacity: Double = 0
	@State private var hasAnimatedOpen: Bool = false
	@State private var isClosingRequested: Bool = false
	@State private var contractionWorkItem: DispatchWorkItem? = nil
	@State private var closeWorkItem: DispatchWorkItem? = nil

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
		ZStack(alignment: .center) {
			// Measure target size using the exact styled text
			Text(message)
				.font(.footnote)
				.padding(.horizontal, 15)
				.fixedSize(horizontal: true, vertical: true)
				.background(
					GeometryReader { proxy in
						Color.clear
							.onAppear {
								measuredWidth = proxy.size.width
								measuredHeight = proxy.size.height
								if !hasAnimatedOpen && !message.isEmpty {
									hasAnimatedOpen = true
									startOpenAnimation()
								}
							}
							.onChange(of: message) { _, newValue in
								measuredWidth = proxy.size.width
								measuredHeight = proxy.size.height
								cancelScheduledAnimations()
								isClosingRequested = false
								if newValue.isEmpty {
									// Hide if message cleared
									requestCloseNow()
								} else {
									// Restart open animation for new message
									startOpenAnimation()
								}
							}
						}
				)
				.hidden()

			// Visible liquid-glass capsule that expands from center
			ZStack {
				Text(message)
					.font(.footnote)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.fixedSize(horizontal: true, vertical: true)
					.opacity(textOpacity)
			}
			.frame(width: max(currentWidth, 0), alignment: .center)
			.clipped()
			.contentShape(Capsule())
			.glassEffect(
				useTint ? .regular.tint(tintColor ?? .clear) : .regular,
				in: Capsule()
			)
			.opacity(outerOpacity)
			.onTapGesture {
				guard tapToClose else { return }
				requestCloseNow()
			}
		}
		.opacity(message.isEmpty ? 0 : 1)
		.allowsHitTesting(!message.isEmpty)
		.accessibilityLabel(message)
		.onDisappear { cancelScheduledAnimations() }
	}

	private func startOpenAnimation() {
		// Optional haptic on show
		// Show an empty pill during drop by keeping width equal to height
		let baselineWidth = max(measuredHeight, 28)
		currentWidth = baselineWidth
		textOpacity = 0
		outerOpacity = 0
		// 0) Drop-in fade before expand
		if dropTime > 0 {
			withAnimation(.easeOut(duration: dropTime)) { outerOpacity = 1 }
		} else {
			outerOpacity = 1
		}

		let startExpand = DispatchWorkItem {
			if let hapticStyle = hapticStyle {
				UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred()
			}
			if isClosingRequested { return }
			// 1) Expand with slight overshoot
			withAnimation(.easeOut(duration: expansionDuration)) {
				currentWidth = max(measuredWidth * (1.0 + overshootPercent), 0)
			}
			// Fade text in during expand
			withAnimation(.easeIn(duration: expansionDuration)) {
				textOpacity = 1
			}
			// 2) After expand, decay back to target width
			let contraction = DispatchWorkItem {
				if isClosingRequested { return }
				withAnimation(.easeOut(duration: contractionDuration)) {
					currentWidth = max(measuredWidth, 0)
				}
				// 3) After decay + hold, close
				let hold = max(0, holdDuration ?? 0)
				let closeItem = DispatchWorkItem {
					if isClosingRequested { return }
					startCloseAnimation()
				}
				closeWorkItem = closeItem
				DispatchQueue.main.asyncAfter(deadline: .now() + contractionDuration + hold, execute: closeItem)
			}
			contractionWorkItem = contraction
			DispatchQueue.main.asyncAfter(deadline: .now() + expansionDuration, execute: contraction)
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + max(0, dropTime), execute: startExpand)
	}

	private func startCloseAnimation() {
		// Fade text out first, then collapse width
		withAnimation(.smooth(duration: 0.2)) {
			textOpacity = 0
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			withAnimation(.smooth(duration: closeDuration)) {
				currentWidth = 0
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + closeDuration) {
				onDismiss?()
			}
		}
	}

	private func requestCloseNow() {
		guard !isClosingRequested else { return }
		isClosingRequested = true
		cancelScheduledAnimations()
		startCloseAnimation()
	}

	private func cancelScheduledAnimations() {
		contractionWorkItem?.cancel()
		contractionWorkItem = nil
		closeWorkItem?.cancel()
		closeWorkItem = nil
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



