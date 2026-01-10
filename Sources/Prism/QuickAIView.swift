import SwiftUI

struct QuickAIView: View {
    var onResize: ((CGSize) -> Void)?
    var onClose: (() -> Void)?

    @ObservedObject var chatManager = ChatManager.shared
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var selectedProvider: String = "Ollama"
    @State private var thinkingLevel: String = "medium"
    @State private var isExpanded: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    // Settings
    @AppStorage("GeminiKey") private var geminiKey: String = ""
    @AppStorage("GeminiModel") private var geminiModel: String = "gemini-1.5-flash"
    @AppStorage("OllamaURL") private var ollamaURL: String = "http://localhost:11434"
    @AppStorage("OllamaModel") private var ollamaModel: String = "gpt-oss:120b-cloud"
    @AppStorage("SystemPrompt") private var systemPrompt: String = ""
    @AppStorage("ShortcutPrivateCloud") private var shortcutPrivateCloud: String = "Ask AI Private"
    @AppStorage("ShortcutOnDevice") private var shortcutOnDevice: String = "Ask AI Device"
    @AppStorage("ShortcutChatGPT") private var shortcutChatGPT: String = "Ask ChatGPT"

    private let geminiService = GeminiService()
    private let ollamaService = OllamaService()
    private let shortcutService = ShortcutService()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if isExpanded {
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            Menu {
                                Picker("Model", selection: $selectedProvider) {
                                    Section("API") {
                                        Text("Gemini API").tag("Gemini API")
                                        Text("Ollama").tag("Ollama")
                                    }
                                    Section("Shortcuts") {
                                        Text("Private Cloud").tag("Private Cloud")
                                        Text("On-Device").tag("On-Device")
                                        Text("ChatGPT").tag("ChatGPT")
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: getProviderIcon(selectedProvider))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .green], startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                                    Text(selectedProvider)
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()

                            Spacer()

                            // New Chat
                            Button(action: {
                                chatManager.deleteAllSessions()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    isExpanded = false
                                }
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("New Chat")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)

                        // Messages
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 16) {
                                    ForEach(chatManager.getCurrentMessages()) { message in
                                        QuickAIMessageView(message: message)
                                    }
                                    if isLoading {
                                        HStack {
                                            TypingIndicator()
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .id("loading")
                                    }
                                }
                                .padding(20)
                            }
                            .onChange(of: chatManager.getCurrentMessages().count) { _, _ in
                                if let lastId = chatManager.getCurrentMessages().last?.id {
                                    withAnimation {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: isLoading) { _, loading in
                                if loading {
                                    withAnimation {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.black.opacity(colorScheme == .dark ? 0.24 : 0.16))
                            .background(
                                .ultraThinMaterial.opacity(colorScheme == .dark ? 0.32 : 0.22))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .padding(.bottom, 10)
                }

                // Input Area
                HStack(alignment: .center, spacing: 12) {
                    TextField("Request...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .lineLimit(1...6)
                        .multilineTextAlignment(.leading)
                        .focused($isFocused)
                        .onSubmit { sendMessage() }

                    // Thinking Level Selector
                    if selectedProvider == "Ollama" || selectedProvider == "Gemini API" {
                        Menu {
                            Picker("Thinking Effort", selection: $thinkingLevel) {
                                Text("Low").tag("low")
                                Text("Medium").tag("medium")
                                Text("High").tag("high")
                            }
                        } label: {
                            Image(systemName: "brain")
                                .font(.system(size: 16))
                                .foregroundColor(
                                    thinkingLevel == "medium" ? Color.teal : Color.green
                                )
                                .padding(6)
                                .background(Color.white.opacity(0.10))
                                .clipShape(Circle())
                        }
                        .menuStyle(.borderlessButton)
                        .help("Reasoning Effort")
                    }

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(sendButtonStyle())
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(16)
                .background(CommandBarBackground(cornerRadius: 26))
            }
        }
        .onAppear {
            isFocused = true
            onResize?(CGSize(width: 700, height: 80))
        }
        .onChange(of: isExpanded) { _, expanded in
            let targetSize =
                expanded ? CGSize(width: 700, height: 520) : CGSize(width: 700, height: 86)
            onResize?(targetSize)
        }
    }

    private func sendButtonStyle() -> AnyShapeStyle {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour >= 19 || hour < 7
        // In dark mode or at night, use a brighter punchy gradient for contrast
        if colorScheme == .dark || isNight {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.white.opacity(0.95), Color.green.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.teal, Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    func getProviderIcon(_ provider: String) -> String {
        switch provider {
        case "On-Device": return "iphone"
        case "Private Cloud": return "lock.icloud"
        case "Gemini API": return "sparkles"
        case "Ollama": return "laptopcomputer"
        case "ChatGPT": return "message"
        default: return "cpu"
        }
    }

    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if !isExpanded {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }

        let content = inputText
        inputText = ""

        let userMsg = Message(content: content, image: nil, isUser: true)
        chatManager.addMessage(userMsg)
        isLoading = true

        chatManager.currentTask = Task {
            if selectedProvider == "Gemini API" {
                if !geminiKey.isEmpty {
                    let aiMsgId = UUID()
                    var aiMsg = Message(content: "", isUser: false)
                    aiMsg.id = aiMsgId

                    DispatchQueue.main.async {
                        self.chatManager.addMessage(aiMsg)
                    }

                    do {
                        var fullContent = ""
                        var fullThinking = ""

                        for try await (contentChunk, thinkingChunk)
                            in geminiService.sendMessageStream(
                                history: chatManager.getCurrentMessages(), apiKey: geminiKey,
                                model: geminiModel, systemPrompt: systemPrompt,
                                thinkingLevel: thinkingLevel)
                        {
                            fullContent += contentChunk
                            if let thinking = thinkingChunk {
                                fullThinking += thinking
                            }

                            let contentToUpdate = fullContent
                            let thinkingToUpdate = fullThinking.isEmpty ? nil : fullThinking

                            DispatchQueue.main.async {
                                self.chatManager.updateMessage(
                                    id: aiMsgId, content: contentToUpdate,
                                    thinkingContent: thinkingToUpdate)
                            }
                        }
                        DispatchQueue.main.async {
                            self.chatManager.finalizeMessageUpdate()
                            self.isLoading = false
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.chatManager.updateMessage(
                                id: aiMsgId, content: "Error: \(error.localizedDescription)")
                            self.chatManager.finalizeMessageUpdate()
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        let aiMsg = Message(
                            content: "Please set your API Key in the main app settings.",
                            isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                }
            } else if selectedProvider == "Ollama" {
                let aiMsgId = UUID()
                var aiMsg = Message(content: "", isUser: false)
                aiMsg.id = aiMsgId

                DispatchQueue.main.async {
                    self.chatManager.addMessage(aiMsg)
                }

                do {
                    var fullContent = ""
                    var fullThinking = ""

                    for try await (contentChunk, thinkingChunk) in ollamaService.sendMessageStream(
                        history: chatManager.getCurrentMessages(), endpoint: ollamaURL,
                        model: ollamaModel, systemPrompt: systemPrompt, thinkingLevel: thinkingLevel
                    ) {
                        fullContent += contentChunk
                        if let thinking = thinkingChunk {
                            fullThinking += thinking
                        }

                        let contentToUpdate = fullContent
                        let thinkingToUpdate = fullThinking.isEmpty ? nil : fullThinking

                        DispatchQueue.main.async {
                            self.chatManager.updateMessage(
                                id: aiMsgId, content: contentToUpdate,
                                thinkingContent: thinkingToUpdate)
                        }
                    }
                    DispatchQueue.main.async {
                        self.chatManager.finalizeMessageUpdate()
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.chatManager.updateMessage(
                            id: aiMsgId, content: "Error: \(error.localizedDescription)")
                        self.chatManager.finalizeMessageUpdate()
                        self.isLoading = false
                    }
                }
            } else {
                // Shortcuts
                let shortcutName: String
                switch selectedProvider {
                case "Private Cloud": shortcutName = shortcutPrivateCloud
                case "On-Device": shortcutName = shortcutOnDevice
                case "ChatGPT": shortcutName = shortcutChatGPT
                default: shortcutName = shortcutPrivateCloud
                }

                // Build transcript
                var transcript = "Please reply to the last message:\n\n"
                for msg in chatManager.getCurrentMessages().suffix(5) {
                    let role = msg.isUser ? "User" : "Assistant"
                    transcript += "\(role): \(msg.content)\n"
                }
                transcript += "Assistant:"

                do {
                    let result = try await shortcutService.runShortcut(
                        name: shortcutName, input: transcript, image: nil)
                    DispatchQueue.main.async {
                        let aiMsg = Message(content: result.0, image: nil, isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        let aiMsg = Message(
                            content: "Error: \(error.localizedDescription)", isUser: false)
                        self.chatManager.addMessage(aiMsg)
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

struct QuickAIMessageView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .font(.system(size: 14))
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.92), Color.cyan.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green], startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.ultraThinMaterial))

                VStack(alignment: .leading, spacing: 8) {
                    if let thinking = message.thinkingContent {
                        DisclosureGroup {
                            Text(thinking)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "brain")
                                    .font(.caption)
                                Text("Reasoning Process")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 4)
                    }

                    MarkdownView(blocks: message.blocks)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()
            }
        }
    }
}

struct CommandBarBackground: View {
    var cornerRadius: CGFloat = 26
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(
                            color: Color.blue.opacity(colorScheme == .dark ? 0.34 : 0.44),
                            location: 0.0),
                        .init(
                            color: Color.green.opacity(colorScheme == .dark ? 0.30 : 0.38),
                            location: 1.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.white.opacity(colorScheme == .dark ? 0.35 : 0.28),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
