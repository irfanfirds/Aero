import SwiftUI

struct ChatTerminalView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var historyStore: HistoryStore
    @State private var input: String = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - TERMINAL BAR
            ZStack {
                Rectangle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 80)
                    .offset(x: 0, y: 5)
                
                Rectangle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 80)
                
                HStack {
                    Text("SYSTEM.AERO // AUDIT_MODE")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(BrutalistTheme.brutalistWhite)
                        .tracking(1)
                    
                    Spacer()
                    
                    if !chatService.messages.isEmpty {
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            chatService.resetChat()
                        }) {
                            ZStack {
                                Capsule()
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(height: 24)
                                    .offset(x: 2, y: 2)
                                Capsule()
                                    .fill(BrutalistTheme.brutalistLavender)
                                    .frame(height: 24)
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10, weight: .black))
                                    Text("CLEAR")
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .padding(.horizontal, 10)
                                Capsule()
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                                    .frame(height: 24)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, BrutalistTheme.spacingM)
                    }
                    
                    Button(action: {
                        FeedbackManager.shared.triggerClack()
                        dismiss()
                    }) {
                        Text("EXIT")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistWhite)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, BrutalistTheme.spacingL)
                .padding(.vertical, BrutalistTheme.spacingM)
                
                Rectangle()
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    .frame(height: 80)
            }
            
            // MARK: - QUOTA METER
            QuotaMeter(
                percentage: chatService.quotaPercentage,
                remaining: chatService.remainingQuota
            )

            // MARK: - MESSAGE LOG
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                        if chatService.messages.isEmpty {
                            VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                                Text("> SYSTEM_INIT")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistCyan)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 4, y: 4)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistWhite)
                                    
                                    Text("AERO AUDIT SYSTEM READY.\nTYPE COMMAND TO BEGIN.")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .padding(BrutalistTheme.spacingL)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            }
                            .padding(.horizontal, BrutalistTheme.spacingL)
                            .padding(.top, BrutalistTheme.spacingL)
                        }
                        
                        ForEach(chatService.messages) { msg in
                            VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                                Text(msg.isUser ? "> USER_INPUT" : "> AERO_LOG")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(msg.isUser ? BrutalistTheme.brutalistCyan : BrutalistTheme.brutalistLime)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 4, y: 4)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(msg.isUser ? BrutalistTheme.brutalistWhite : BrutalistTheme.brutalistLavender)
                                    
                                    Text(msg.content)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .padding(BrutalistTheme.spacingL)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            }
                            .padding(.horizontal, BrutalistTheme.spacingL)
                            .id(msg.id)
                        }
                        
                        if chatService.isTyping {
                            VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                                Text("> AERO_PROCESSING")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistYellow)
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 4, y: 4)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistYellow)
                                    
                                    HStack(spacing: BrutalistTheme.spacingS) {
                                        Text("ANALYZING...")
                                            .font(.system(size: 14, weight: .black, design: .monospaced))
                                            .foregroundColor(BrutalistTheme.brutalistBlack)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: BrutalistTheme.brutalistBlack))
                                    }
                                    .padding(BrutalistTheme.spacingL)
                                    
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            }
                            .padding(.horizontal, BrutalistTheme.spacingL)
                            .id("typing")
                        }
                    }
                    .padding(.vertical, BrutalistTheme.spacingL)
                }
                .background(BrutalistTheme.brutalistWhite)
                .onChange(of: isInputFocused) { _, focused in
                    if focused {
                        // Smoothly scroll down to typing indicator or last log item when keyboard expands
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if chatService.isTyping {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                } else if let lastMessage = chatService.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onTapGesture {
                    isInputFocused = false
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .ignoresSafeArea(.keyboard, edges: .bottom) // Ensures content elements stack beautifully
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(BrutalistTheme.brutalistBlack)
                        .frame(height: 2)
                    
                    HStack(spacing: BrutalistTheme.spacingM) {
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 5, y: 5)
                            
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistWhite)
                            
                            TextField("COMMAND...", text: $input)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .padding(BrutalistTheme.spacingM)
                                .focused($isInputFocused)
                                .submitLabel(.send)
                                .onSubmit {
                                    sendMessage()
                                }
                            
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                        .frame(height: 56)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .frame(width: 48, height: 48)
                                    .offset(x: 5, y: 5)
                                
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistYellow)
                                    .frame(width: 48, height: 48)
                                
                                Text(">_")
                                    .font(.system(size: 18, weight: .black, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    .frame(width: 48, height: 48)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    .padding(.vertical, BrutalistTheme.spacingM)
                }
                .background(BrutalistTheme.brutalistWhite)
            }
            .ignoresSafeArea(.keyboard, edges: [])
        }
    }
    
    private func sendMessage() {
        FeedbackManager.shared.triggerClack()
        let msg = input
        input = ""
        guard !msg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            await chatService.sendMessage(msg, inventory: historyStore.foodItems)
        }
    }
}

// MARK: - Quota Meter Component
struct QuotaMeter: View {
    let percentage: Double
    let remaining: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
            HStack {
                Text("SYSTEM_POWER:")
                    .font(.system(size: BrutalistTheme.caption, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                Spacer()
                
                Text("\(remaining) / 250 RPD")
                    .font(.system(size: BrutalistTheme.caption, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 6)
                    .offset(x: 2, y: 2)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(meterColor)
                        .frame(width: geo.size.width * CGFloat(percentage))
                        .frame(height: 6)
                }
                .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 2)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 1)
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, BrutalistTheme.spacingL)
        .padding(.vertical, BrutalistTheme.spacingS)
        .background(BrutalistTheme.brutalistWhite)
    }
    
    var meterColor: Color {
        if percentage > 0.5 { return BrutalistTheme.brutalistLime }
        if percentage > 0.2 { return BrutalistTheme.brutalistYellow }
        return BrutalistTheme.brutalistRed
    }
}

#Preview {
    ChatTerminalView()
        .environmentObject(ChatService())
        .environmentObject(HistoryStore())
}
