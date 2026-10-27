import SwiftUI
import UIKit

@MainActor
struct DataExportButton: View {
    let title: String
    let prepare: () throws -> ExportCopy
    @State private var presentedCopy: ExportCopy?
    @State private var lease: ExportCopy?
    @State private var errorMessage: String?

    var body: some View {
        Button(title) {
            guard lease == nil else { return }
            do {
                let copy = try prepare()
                lease = copy
                presentedCopy = copy
            } catch { errorMessage = error.localizedDescription }
        }
        .disabled(lease != nil)
        .sheet(item: $presentedCopy, onDismiss: cleanup) { copy in
            ActivitySheet(url: copy.file)
        }
        .alert("Export", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func cleanup() {
        guard let copy = lease else { return }
        do { try DataExport.remove(copy) }
        catch { errorMessage = "The shared copy could not be cleared from temporary storage: \(error.localizedDescription)" }
        lease = nil
    }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
