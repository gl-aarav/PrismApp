# Prism - Your Ultimate Native AI Companion for macOS

![Prism App Icon](AppIcon.png)

**Prism** is a powerful, native macOS application that brings the power of modern AI directly to your desktop. Built with SwiftUI and designed with a stunning "Liquid Glass" aesthetic, Prism integrates seamlessly into your Mac workflow, offering a unified interface for Google Gemini, local Ollama models, and Apple Shortcuts.

---

## 🚀 Key Features

### 🧠 Multi-Model Intelligence
*   **Google Gemini**: Harness the power of Google's latest cloud models (Gemini 1.5 Pro/Flash) for complex reasoning, coding, and multimodal analysis.
*   **Ollama Integration**: Run privacy-focused local models (like Llama 3, DeepSeek, Mistral) directly on your machine. Zero data leaves your device.
*   **Apple Shortcuts**: Trigger system automations, control your smart home, or chain complex workflows directly from the chat.

### 🖥️ Versatile Interfaces
Prism adapts to how you work with three distinct modes, all **synchronized** in real-time:
1.  **Main Window**: A full-featured chat interface for deep work and long conversations.
2.  **Menu Bar App**: Always one click away for quick questions and status checks.
3.  **Quick AI Panel** (`Ctrl + Space`): A Spotlight-like floating search bar. Summon it instantly from anywhere to ask a question, then dismiss it just as fast.

### ✍️ Rich Chat Experience
*   **Advanced Math Rendering**: 
    *   **Block Math**: Beautiful LaTeX rendering for complex equations using `$$...$$`.
    *   **Inline Math**: Seamless text-based math support (`$...$`) with automatic conversion of Greek letters (`\alpha` → α), fractions (`\frac` → `/`), and operators.
*   **Code Highlighting**: Syntax highlighting for all major programming languages with one-click copy.
*   **Thinking Process**: View the internal "thought process" of reasoning models (like DeepSeek R1) in a collapsible section.
*   **Image Analysis**: Drag and drop images to analyze them with multimodal models.
*   **Global Sync**: Start a chat in the Quick Panel, continue it in the Menu Bar, and finish it in the Main Window.

### ⚡️ Performance & Design
*   **Native macOS**: Built with SwiftUI for blazing fast performance and low memory usage.
*   **Streaming**: Character-by-character streaming responses for immediate feedback.
*   **Customizable**: Choose your preferred model, system prompt, and background aesthetics.

---

## 📥 Installation

1.  Go to the **[Releases](../../releases)** page.
2.  Download the latest `Prism_Installer.dmg`.
3.  Open the disk image and drag **Prism** to your **Applications** folder.
4.  Launch Prism!

> **Note**: On first launch, you may need to right-click the app and select "Open" if Gatekeeper prompts you.

---

## ⚙️ Configuration

Click the **Gear Icon** in the main window to access Settings:

### 1. Google Gemini
*   Get your API key from [Google AI Studio](https://aistudio.google.com/).
*   Paste it into the **API Key** field.
*   Set your model (default: `gemini-1.5-flash`).

### 2. Ollama (Local Models)
*   Install [Ollama](https://ollama.com/) and run `ollama serve`.
*   Pull a model (e.g., `ollama run llama3`).
*   Enter the model name in Prism settings.

### 3. Quick AI Hotkey
*   The default hotkey is **Control + Space**.
*   Toggle the panel to ask quick questions without leaving your current app.

---

## 📝 Usage Tips

### Math & LaTeX
Prism supports extensive LaTeX formatting:
*   **Fractions**: `\frac{a}{b}` converts to `(a)/(b)` inline.
*   **Greek**: `\alpha`, `\beta`, `\Delta` convert to α, β, Δ.
*   **Roots**: `\sqrt{x}` converts to `√(x)`.
*   **Boxed**: `\boxed{answer}` highlights the result.

### Shortcuts
You can map specific phrases to Apple Shortcuts. For example, map "Generate Image" to a shortcut that uses DALL-E or Stable Diffusion, and trigger it directly from Prism.

---

## 🔒 Privacy

*   **Local Storage**: All chat history is stored locally on your Mac in JSON format.
*   **Ollama**: When using Ollama, your data never leaves your computer.
*   **Direct Connections**: Prism connects directly to the APIs you configure (Google, Ollama). No middleman servers.

---

## 📄 License

Prism is open-source software!

---

**Developed by Aarav Goyal**
