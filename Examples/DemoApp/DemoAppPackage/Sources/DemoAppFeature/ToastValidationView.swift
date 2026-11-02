#if DEBUG
import Beautiful_iOS_Components
import OSLog
import SwiftUI

struct ToastValidationView: View {
    let largeText: Bool
    let slowOpening: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var message = "Saved to your collection."
    @State private var showing = false
    @State private var dismissals = 0
    @State private var replacementRun = 0
    @State private var removeInstead = false
    @State private var dropTime = 0.1
    @State private var holdTime = 8.0

    var body: some View {
        VStack(spacing: 20) {
            Text("Component verification fixture")
                .font(.headline)
            Text("Actual LiquidGlassToast, with synthetic messages.")
                .font(.caption)
            Button("Show toast") {
                dismissals = 0
                message = largeText
                    ? "Your changes were saved. All of this message must stay readable, including the final words."
                    : "Saved to your collection."
                dropTime = slowOpening ? 2.5 : 0.1
                holdTime = 8
                showing = true
            }
            .accessibilityIdentifier("show-validation-toast")
            Button("Replace before opening") {
                removeInstead = false
                replacementRun += 1
            }
            .accessibilityIdentifier("replace-validation-toast")
            Button("Remove before opening") {
                removeInstead = true
                replacementRun += 1
            }
            .accessibilityIdentifier("remove-validation-toast")
            Button("Clear message") {
                message = ""
            }
            .accessibilityIdentifier("clear-validation-toast")
            Text("Dismissals: \(dismissals)")
                .accessibilityIdentifier("validation-dismissals")
            Text("Reduce Motion: \(reduceMotion ? "On" : "Off")")
                .accessibilityIdentifier("validation-reduce-motion")
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .overlay(alignment: .top) {
            if showing {
                LiquidGlassToast(
                    message: message,
                    dropTime: dropTime,
                    expansionDuration: 0.1,
                    overshootPercent: 0.055,
                    contractionDuration: 0.1,
                    holdDuration: holdTime,
                    closeDuration: 0.1,
                    hapticStyle: nil,
                    onDismiss: {
                        dismissals += 1
                        showing = false
                    }
                )
                .dynamicTypeSize(largeText ? .accessibility5 : .large)
                .accessibilityIdentifier("validation-toast")
                .padding(.horizontal, 20)
                .padding(.top, 360)
            }
        }
        .task(id: replacementRun) {
            guard replacementRun > 0 else { return }
            dismissals = 0
            showing = false
            message = "Old message"
            dropTime = 0.6
            holdTime = 0.2
            showing = true
            do {
                try await Task.sleep(for: .milliseconds(150))
                if removeInstead {
                    showing = false
                } else {
                    message = "Replacement message stays visible."
                    dropTime = 0.1
                    holdTime = 8
                }
            } catch is CancellationError {
                return
            } catch {
                Logger(subsystem: "ComponentsDemo", category: "Validation")
                    .error("Fixture timing failed: \(error.localizedDescription)")
            }
        }
    }
}
#endif
