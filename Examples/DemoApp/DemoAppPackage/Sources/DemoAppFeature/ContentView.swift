import Beautiful_iOS_Components
import SwiftUI

public struct ContentView: View {
    public var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--toast-validation") {
            ToastValidationView(
                largeText: ProcessInfo.processInfo.arguments.contains("--toast-validation-large"),
                slowOpening: ProcessInfo.processInfo.arguments.contains("--toast-validation-slow")
            )
        } else {
            catalog
        }
        #else
        catalog
        #endif
    }

    private var catalog: some View {
        NavigationStack {
            List {
                Section("Liquid Glass") {
                    NavigationLink("Liquid Glass Toast") {
                        LiquidGlassToastDemoView()
                    }
                }
            }
            .navigationTitle("Components Catalog")
        }
    }

    public init() {}
}
