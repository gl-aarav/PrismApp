import Foundation

func testParser() async {
    let chunks = [
        "Here is ", "some text\n<th", "ink>\nThis is ", "thought.\n</", "think>\nAnswer.",
    ]

    var buffer = ""
    var isThinking = false

    print("Starting parser test...")

    for chunk in chunks {
        print("Received chunk: '\(chunk.replacingOccurrences(of: "\n", with: "\\n"))'")
        buffer += chunk

        while true {
            if !isThinking {
                if let range = buffer.range(of: "<think>") {
                    let preTag = buffer[..<range.lowerBound]
                    if !preTag.isEmpty {
                        print("Yield Content: '\(preTag)'")
                    }
                    buffer.removeSubrange(..<range.upperBound)
                    isThinking = true
                    print("State changes to THINKING")
                } else {
                    if buffer.count > 7 {
                        let keepIndex = buffer.index(buffer.endIndex, offsetBy: -7)
                        let emitStr = buffer[..<keepIndex]
                        print("Yield Content (Buffered): '\(emitStr)'")
                        buffer.removeSubrange(..<keepIndex)
                    }
                    break
                }
            } else {
                if let range = buffer.range(of: "</think>") {
                    let preTag = buffer[..<range.lowerBound]
                    if !preTag.isEmpty {
                        print("Yield Thinking: '\(preTag)'")
                    }
                    buffer.removeSubrange(..<range.upperBound)
                    isThinking = false
                    print("State changes to CONTENT")
                } else {
                    if buffer.count > 8 {
                        let keepIndex = buffer.index(buffer.endIndex, offsetBy: -8)
                        let emitStr = buffer[..<keepIndex]
                        print("Yield Thinking (Buffered): '\(emitStr)'")
                        buffer.removeSubrange(..<keepIndex)
                    }
                    break
                }
            }
        }
    }

    // Flush
    if !buffer.isEmpty {
        if isThinking {
            print("Yield Thinking (Flush): '\(buffer)'")
        } else {
            print("Yield Content (Flush): '\(buffer)'")
        }
    }
}

await testParser()
