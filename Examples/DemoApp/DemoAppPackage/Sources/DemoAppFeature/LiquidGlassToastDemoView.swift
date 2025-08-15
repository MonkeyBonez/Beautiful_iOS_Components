import SwiftUI
import Beautiful_iOS_Components

struct LiquidGlassToastDemoView: View {
    @State private var message: String = "Liquid Glass Toast"
    @State private var dropTime: Double = 1.2
    @State private var expansionDuration: Double = 0.5
    @State private var overshootPercent: Double = 0.055
    @State private var contractionDuration: Double = 2.3
    @State private var holdDurationEnabled: Bool = true
    @State private var holdDuration: Double = 0.4
    @State private var closeDuration: Double = 0.35
    @State private var tapToClose: Bool = true
    @State private var hapticEnabled: Bool = true
    @State private var blankWhileShowing: Bool = true
    @State private var blankColor: Color = .white
    @State private var tintEnabled: Bool = false
    @State private var tintColor: Color = .blue.opacity(0.4)
    @State private var showToast: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Form {
                Section("Message") {
                    TextField("Message", text: $message)
                }
                Section("Timings (seconds)") {
                    HStack { Text("Drop") ; Spacer() ; Text(String(format: "%.2f", dropTime)) }
                    Slider(value: $dropTime, in: 0...2, step: 0.05)

                    HStack { Text("Expand") ; Spacer() ; Text(String(format: "%.2f", expansionDuration)) }
                    Slider(value: $expansionDuration, in: 0...1.5, step: 0.05)

                    HStack { Text("Overshoot %") ; Spacer() ; Text(String(format: "+%.1f%%", overshootPercent * 100)) }
                    Slider(value: $overshootPercent, in: 0.0...0.2, step: 0.005)

                    HStack { Text("Contraction") ; Spacer() ; Text(String(format: "%.2f", contractionDuration)) }
                    Slider(value: $contractionDuration, in: 0...4, step: 0.05)

                    Toggle("Hold Enabled", isOn: $holdDurationEnabled)
                    if holdDurationEnabled {
                        HStack { Text("Hold") ; Spacer() ; Text(String(format: "%.2f", holdDuration)) }
                        Slider(value: $holdDuration, in: 0...2, step: 0.05)
                    }

                    HStack { Text("Close") ; Spacer() ; Text(String(format: "%.2f", closeDuration)) }
                    Slider(value: $closeDuration, in: 0.1...1.0, step: 0.05)
                }
                Section("Behavior") {
                    Toggle("Tap to Close", isOn: $tapToClose)
                    Toggle("Haptic", isOn: $hapticEnabled)
                }
                Section("Appearance") {
                    HStack(spacing: 12) {
                        Text("Tint")
                        Spacer()
                        Toggle("", isOn: $tintEnabled)
                            .labelsHidden()
                        ColorPicker("", selection: $tintColor, supportsOpacity: true)
                            .labelsHidden()
                            .disabled(!tintEnabled)
                    }
                }
                Section("Environment") {
                    HStack(spacing: 12) {
                        Text("Background")
                        Spacer()
                        Toggle("", isOn: $blankWhileShowing)
                            .labelsHidden()
                        ColorPicker("", selection: $blankColor, supportsOpacity: true)
                            .labelsHidden()
                            .disabled(!blankWhileShowing)
                    }
                }
                Section {
                    Button("Show Toast") { showToast = true }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("LiquidGlassToast")
            .navigationBarBackButtonHidden(showToast && blankWhileShowing)
            .toolbar {
                if showToast && blankWhileShowing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showToast = false }) {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
            .allowsHitTesting(!(showToast && blankWhileShowing))

            if showToast {
                if blankWhileShowing {
                    blankColor.ignoresSafeArea()
                }
                LiquidGlassToast(
                    message: message,
                    dropTime: dropTime,
                    expansionDuration: expansionDuration,
                    overshootPercent: overshootPercent,
                    contractionDuration: contractionDuration,
                    holdDuration: holdDurationEnabled ? holdDuration : nil,
                    closeDuration: closeDuration,
                    tapToClose: tapToClose,
                    useTint: tintEnabled,
                    tintColor: tintEnabled ? tintColor : nil,
                    hapticStyle: hapticEnabled ? .soft : nil,
                    onDismiss: { showToast = false }
                )
                .padding(.top, 10)
            }
        }
    }
}
