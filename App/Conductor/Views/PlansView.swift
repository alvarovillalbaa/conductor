import ConductorCore
import SwiftUI

@MainActor
struct PlansView: View {
    let store: ConductorStore
    @State private var pendingDelete: TaskPlan?

    var body: some View {
        List {
            if store.isReadOnly { RecoverySection(store: store) }
            if store.notice != nil { Section { NoticeView(store: store) }.listRowBackground(Color.clear) }
            if store.workspace.plans.isEmpty {
                ContentUnavailableView {
                    Label("Bring the finish together", systemImage: "point.3.connected.trianglepath.dotted")
                } description: {
                    Text("Make a plan with the tasks you need to coordinate. Conductor will work backward from one shared finish time.")
                } actions: {
                    Button("Create a Plan") { store.createPlan() }.buttonStyle(.borderedProminent).disabled(store.isReadOnly)
                }
                .listRowBackground(Color.clear)
            } else {
                Section("Your plans") {
                    ForEach(store.workspace.plans) { plan in
                        NavigationLink(value: plan.id) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(plan.title).font(.headline)
                                Text("\(plan.tasks.count) tasks · longest \(TimeText.duration(TimeInterval(plan.tasks.map(\.durationSeconds).max() ?? 0)))")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.vertical, 5)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) { pendingDelete = plan }.disabled(store.isReadOnly)
                            Button("Edit") { store.editPlan(plan) }.tint(.indigo).disabled(store.isReadOnly)
                        }
                    }
                }
            }
            Section {
                Text("Plans stay on this device. A run keeps its own task definitions when you edit its plan.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.listRowBackground(Color.clear)
        }
        .navigationTitle("Conductor")
        .toolbar {
            Button { store.createPlan() } label: { Label("New Plan", systemImage: "plus") }
                .disabled(store.isReadOnly || store.workspace.plans.count >= ScheduleEngine.maximumPlans)
                .keyboardShortcut("n", modifiers: .command)
        }
        .navigationDestination(for: UUID.self) { id in PlanDetailView(id: id, store: store) }
        .confirmationDialog("Delete this plan?", isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible) {
                if let plan = pendingDelete {
                    Button("Delete \(plan.title)", role: .destructive) {
                        store.deletePlan(id: plan.id, expectedRevision: plan.revision)
                        pendingDelete = nil
                    }
                }
                Button("Keep Plan", role: .cancel) { pendingDelete = nil }
            } message: { Text("An existing run keeps its frozen copy of these tasks.") }
    }
}
