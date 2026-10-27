import SwiftUI

@MainActor
struct NoticeView: View {
    let store: ConductorStore

    var body: some View {
        if let notice = store.notice {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notice.isError ? "exclamationmark.triangle" : "info.circle")
                    .foregroundStyle(notice.isError ? Color.orange : Color.secondary)
                Text(notice.message).font(.callout).textSelection(.enabled)
                Spacer(minLength: 0)
                Button { store.notice = nil } label: { Image(systemName: "xmark") }
                    .accessibilityLabel("Dismiss message")
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
