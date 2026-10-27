import SwiftUI

@main
@MainActor
struct ConductorApp: App {
    @State private var store = ConductorStore()

    var body: some Scene {
        WindowGroup { AppRootView(store: store) }
    }
}
