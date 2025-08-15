import SwiftUI
import Beautiful_iOS_Components

public struct ContentView: View {
    public var body: some View {
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
