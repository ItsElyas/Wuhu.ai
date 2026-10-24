import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @State private var viewModel = ChatViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            VStack(spacing: 0) {
                Text(app.chatOrchestrator.backendStatus)
                    .font(.caption2)
                    .foregroundStyle(app.chatOrchestrator.usesRemoteLLM ? Color.secondary : Color.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .accessibilityLabel(app.chatOrchestrator.backendStatus)
                messageList
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                composer(viewModel: viewModel)
            }
            .navigationTitle("Chat")
            .task {
                await viewModel.prepareSessionIfNeeded(
                    orchestrator: app.chatOrchestrator,
                    app: app,
                    modelContext: modelContext
                )
            }
        }
    }

    private var messageList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if messages.isEmpty, app.chatOrchestrator.phase == .idle {
                    Text("Wellness chat only — not medical advice. Say if a body part hurts or feels better to update your Body Map.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                ForEach(messages, id: \.id) { message in
                    messageBubble(message)
                }
                if let phase = app.chatOrchestrator.phase.statusText {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(phase)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func composer(viewModel: ChatViewModel) -> some View {
        @Bindable var viewModel = viewModel
        return HStack(spacing: 8) {
            TextField("Ask a health question", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button {
                Task {
                    await viewModel.send(
                        orchestrator: app.chatOrchestrator,
                        app: app,
                        modelContext: modelContext
                    )
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(
                viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || app.chatOrchestrator.phase != .idle
            )
        }
        .padding()
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content)
                .padding(12)
                .background(
                    message.role == .user ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: 14)
                )
            if message.role != .user { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}
