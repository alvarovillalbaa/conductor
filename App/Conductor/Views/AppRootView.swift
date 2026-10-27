import SwiftUI

@MainActor
struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var store: ConductorStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack { PlansView(store: store) }
                .tabItem { Label("Plans", systemImage: "list.bullet.rectangle") }.tag(AppTab.plans)
            NavigationStack { RunView(store: store) }
                .tabItem { Label("Current Run", systemImage: "timer") }.tag(AppTab.run)
            NavigationStack { SettingsView(store: store) }
                .tabItem { Label("Settings", systemImage: "gearshape") }.tag(AppTab.settings)
        }
        .tint(.indigo)
        .sheet(item: $store.sheet) { sheet in
            switch sheet {
            case .plan(let context): PlanEditorView(context: context, store: store)
            case .run(let context): RunSetupView(context: context, store: store)
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { store.reconcileReminders() }
        }
    }
}
