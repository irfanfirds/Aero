import Foundation
import Combine
import FirebaseAI // Required to parse the underlying SDK error types

enum AIState {
    case idle, thinking, speaking
}

class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var currentState: AIState = .idle
    
    // Explicitly published values so SwiftUI views update automatically
    @Published var remainingQuota: Int = 250
    @Published var quotaPercentage: Double = 1.0
    
    struct ChatMessage: Identifiable, Codable {
        let id: UUID
        let content: String
        let isUser: Bool
        let timestamp: Date
        
        init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
            self.id = id
            self.content = content
            self.isUser = isUser
            self.timestamp = timestamp
        }
    }

    init() {
        // SHORT-CIRCUIT FOR XCODE PREVIEWS
        // Stops execution here to prevent live AI service configuration calls from crashing the preview
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Setup friendly mock states so your preview canvas UI displays values cleanly
            self.remainingQuota = 175
            self.quotaPercentage = 175.0 / 250.0
            
            // Optional mock message to populate the preview UI out-of-the-box
            self.messages = [
                ChatMessage(content: "Hello! I am your Aero AI Assistant. How can I help you manage your kitchen inventory today?", isUser: false)
            ]
            return
        }
        
        updateQuotaValues()
    }
    
    /// Helper method to synchronize service values with published properties
    private func updateQuotaValues() {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        
        let currentQuota = AeroAIService.shared.getRemainingQuota()
        self.remainingQuota = currentQuota
        self.quotaPercentage = Double(currentQuota) / 250.0
    }

    func sendMessage(_ text: String, inventory: [FoodItem]) async {
        // Prevent network/service hitting if accidentally triggered inside previews
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            await MainActor.run {
                self.messages.append(ChatMessage(content: text, isUser: true))
                self.currentState = .thinking
                self.isTyping = true
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self.isTyping = false
                self.currentState = .idle
                self.messages.append(ChatMessage(content: "This is a simulated AI response running inside Xcode Preview mode.", isUser: false))
            }
            return
        }

        await MainActor.run {
            self.messages.append(ChatMessage(content: text, isUser: true))
            self.isTyping = true
            self.currentState = .thinking
        }
        
        do {
            let response = try await AeroAIService.shared.getChatResponse(userMessage: text, inventory: inventory)
            await MainActor.run {
                if !response.isEmpty {
                    self.messages.append(ChatMessage(content: response, isUser: false))
                }
                self.isTyping = false
                self.currentState = .idle
                self.updateQuotaValues() // Refresh quota on successful call
            }
        } catch {
            await MainActor.run {
                self.isTyping = false
                self.currentState = .idle
                
                // 🔍 --- CRITICAL AERO DEBUG LOG PRINT BLOCK ---
                print("\n┌────────────────────────────────────────────────────────┐")
                print("│              AERO CRITICAL NETWORK DEBUG LOG            │")
                print("└────────────────────────────────────────────────────────┘")
                print("👉 Raw Error Object Type: \(type(of: error))")
                print("👉 Raw Error Details: \(error)")

                // Instead of casting to FirebaseAI.GenerateContentError,
                // use the NSError bridge to inspect the underlying error domain and code.
                let nsError = error as NSError
                print("👉 Error Domain: \(nsError.domain)")
                print("👉 Error Code: \(nsError.code)")
                print("👉 User Info: \(nsError.userInfo)")
                print("──────────────────────────────────────────────────────────\n")
                
                // Fallback text outputted directly to your custom purple brutalist log screen
                let displayError = error.localizedDescription
                self.messages.append(ChatMessage(content: "SYSTEM_ERR: \(displayError.uppercased())", isUser: false))
                
                self.updateQuotaValues()
            }
        }
    }
            
    func resetChat() {
        messages.removeAll()
        currentState = .idle
        isTyping = false
    }
}
