#if canImport(UIKit)
import Beautiful_iOS_Components
import SwiftUI
import Testing
import UIKit

@Test("A long accessibility-size toast fits its proposed width")
@MainActor
func longToastFitsItsContainer() {
    let toast = LiquidGlassToast(
        message: "Your changes were saved. All of this message must stay readable, including the final words.",
        hapticStyle: nil
    )
    .dynamicTypeSize(.accessibility5)
    let host = UIHostingController(rootView: toast)
    let size = host.sizeThatFits(in: CGSize(width: 320, height: 1000))
    #expect(size.width <= 320)
}
#endif
