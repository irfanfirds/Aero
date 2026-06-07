import SwiftUI

struct AIOrbView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var historyStore: HistoryStore
    @State private var messageText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (FIXED: No Apple Back Button, Smaller Clear Button)
            ZStack {
                // Shadow
                Rectangle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 80)
                    .offset(x: 0, y: 5)
                
                // Fill
                Rectangle()
                    .fill(BrutalistTheme.brutalistWhite)
                    .frame(height: 80)
                
                // Content
                HStack {
                    // Back Button (FIXED: Sandwich Method)
                    Button(action: {
                        FeedbackManager.shared.triggerClack()
                        dismiss()
                    }) {
                        ZStack {
                            // Shadow
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 4, height: 4)
                                .offset(x: 4, y: 4)
                            
                            // Fill
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 44, height: 44)
                            
                            // Content
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(BrutalistTheme.brutalistWhite)
                            
                            // Border
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: BrutalistTheme.spacingXS) {
                        Text("AI CHEF CORE")
                            .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        Text(stateLabelText)
                            .font(.system(size: BrutalistTheme.caption, weight: BrutalistTheme.fontBold, design: .monospaced))
                            .foregroundColor(stateLabelColor)
                    }
                    
                    Spacer()
                    
                    // Clear History Button (FIXED: Smaller box, bigger text, within borders)
                    if !chatService.messages.isEmpty {
                        Button(action: {
                            FeedbackManager.shared.triggerClack()
                            chatService.resetChat()
                        }) {
                            ZStack {
                                // Shadow
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistBlack)
                                    .offset(x: 2, y: 2)
                                
                                // Fill (FIXED: Smaller box)
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistLavender)
                                
                                // Content (FIXED: Bigger text, tighter padding)
                                Text("CLEAR")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 3)
                                
                                // Border
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, BrutalistTheme.spacingL)
                .padding(.vertical, BrutalistTheme.spacingM)
                
                // Border
                Rectangle()
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    .frame(height: 80)
            }
            
            // MARK: - Quota Meter (FIXED: Different Design from ChatTerminalView)
            QuotaMeterOrb(
                percentage: chatService.quotaPercentage,
                remaining: chatService.remainingQuota
            )
            
            // MARK: - AI Orb Visualization (State-Driven)
            VStack(spacing: BrutalistTheme.spacingM) {
                AIChefOrbVisualization()
                    .environmentObject(chatService)
                    .padding(.top, BrutalistTheme.spacingL)
                
                // Status Badge (FIXED: Sandwich Method - Dynamic Based on State)
                ZStack {
                    // Shadow
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .fill(BrutalistTheme.brutalistBlack)
                        .offset(x: 3, y: 3)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .fill(statusBadgeColor)
                    
                    // Content
                    HStack(spacing: BrutalistTheme.spacingS) {
                        Circle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(width: 8, height: 8)
                            .opacity(statusDotOpacity)
                            .scaleEffect(statusDotScale)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true),
                                value: chatService.currentState
                            )
                        
                        Text(statusBadgeText)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingM)
                    .padding(.vertical, BrutalistTheme.spacingS)
                    
                    
                    
                    
                    // Border
                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                }
            }
            .padding(.vertical, BrutalistTheme.spacingL)
            
            
            // MARK: - Chat Messages Area (FIXED: Same Logic as ChatTerminalView)
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                        // Welcome Message
                        if chatService.messages.isEmpty {
                            WelcomeMessageCard()
                                .padding(.horizontal, BrutalistTheme.spacingL)
                        }
                        
                        // Chat Messages
                        ForEach(chatService.messages) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                                .padding(.horizontal, BrutalistTheme.spacingL)
                        }
                        
                        // Typing Indicator
                        if chatService.isTyping {
                            TypingIndicator()
                                .padding(.horizontal, BrutalistTheme.spacingL)
                        }
                        
                        // Spacer to push content up when keyboard appears (FIXED: Same as ChatTerminalView)
                        Spacer()
                            .frame(height: keyboardHeight > 0 ? keyboardHeight : 0)
                            .id("inputSpacer")
                    }
                    .padding(.vertical, BrutalistTheme.spacingM)
                }
                .background(BrutalistTheme.brutalistWhite)
                .onChange(of: isInputFocused) { _, focused in
                    if focused {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("inputSpacer", anchor: .bottom)
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
            }

            // MARK: - Input Area (FIXED: Same Logic as ChatTerminalView)
            VStack(spacing: 0) {
                // Divider
                Rectangle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 3)
                
                HStack(spacing: BrutalistTheme.spacingM) {
                    // Text Input (FIXED: Sandwich Method - Touchable)
                    ZStack {
                        // Shadow (Non-interactive)
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistBlack)
                            .offset(x: 5, y: 5)
                            .allowsHitTesting(false)
                        
                        // Fill (Non-interactive)
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .fill(BrutalistTheme.brutalistWhite)
                            .allowsHitTesting(false)
                        
                        // Content - TextField (Interactive, on top)
                        TextField("Ask AI Chef anything...", text: $messageText, axis: .vertical)
                            .font(.system(size: BrutalistTheme.bodyMedium, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .padding(BrutalistTheme.spacingM)
                            .lineLimit(1...4)
                            .focused($isInputFocused)
                            .disabled(chatService.currentState == .thinking || chatService.currentState == .speaking)
                            .submitLabel(.send)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        // Border (Non-interactive)
                        RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                            .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            .allowsHitTesting(false)
                    }
                    
                    // Send Button (FIXED: Sandwich Method)
                    Button(action: {
                        sendMessage()
                    }) {
                        ZStack {
                            // Shadow
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 56, height: 56)
                                .offset(x: 5, y: 5)
                            
                            // Fill
                            Circle()
                                .fill(BrutalistTheme.brutalistCyan)
                                .frame(width: 56, height: 56)
                            
                            // Content
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            // Border
                            Circle()
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                .frame(width: 56, height: 56)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        chatService.currentState == .thinking ||
                        chatService.currentState == .speaking
                    )
                    .opacity(
                        (messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         chatService.currentState == .thinking ||
                         chatService.currentState == .speaking) ? 0.5 : 1.0
                    )
                }
                .padding(BrutalistTheme.spacingL)
            }
            .background(BrutalistTheme.brutalistWhite)
        }
        .background(Color(hex: "#F5F5F5"))
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    // MARK: - Computed Properties for State
    private var stateLabelText: String {
        switch chatService.currentState {
        case .idle:
            return "NEURAL NETWORK ACTIVE"
        case .thinking:
            return "PROCESSING REQUEST..."
        case .speaking:
            return "GENERATING RESPONSE..."
        }
    }
    
    private var stateLabelColor: Color {
        switch chatService.currentState {
        case .idle:
            return BrutalistTheme.brutalistCyan
        case .thinking:
            return BrutalistTheme.brutalistYellow
        case .speaking:
            return BrutalistTheme.brutalistLime
        }
    }
    
    private var statusBadgeText: String {
        switch chatService.currentState {
        case .idle:
            return "READY TO ASSIST"
        case .thinking:
            return "ANALYZING..."
        case .speaking:
            return "RESPONDING..."
        }
    }
    
    private var statusBadgeColor: Color {
        switch chatService.currentState {
        case .idle:
            return BrutalistTheme.brutalistLime
        case .thinking:
            return BrutalistTheme.brutalistYellow
        case .speaking:
            return BrutalistTheme.brutalistCyan
        }
    }
    
    private var statusDotOpacity: Double {
        chatService.currentState == .idle ? 1.0 : 0.5
    }
    
    private var statusDotScale: CGFloat {
        chatService.currentState == .thinking ? 1.5 : 1.0
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        FeedbackManager.shared.triggerClack()
        messageText = ""
        
        Task {
            await chatService.sendMessage(text, inventory: historyStore.foodItems)
        }
    }
}

// MARK: - Quota Meter Component for AI Orb View (FIXED: Different Design from ChatTerminalView)
struct QuotaMeterOrb: View {
    let percentage: Double
    let remaining: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
            HStack {
                Text("QUOTA_STATUS:")
                    .font(.system(size: BrutalistTheme.caption, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                Spacer()
                
                Text("\(remaining) / 500 RPD")
                    .font(.system(size: BrutalistTheme.caption, weight: .black, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
            }
            
            // The Progress Bar (FIXED: Sandwich Method, Different Style)
            ZStack(alignment: .leading) {
                // Shadow
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(height: 8)
                    .offset(x: 2, y: 2)
                
                // Background Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(BrutalistTheme.brutalistCream)
                    .frame(height: 8)
                
                // Progress Fill
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(meterColor)
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.0, percentage))))
                        .frame(height: 8)
                }
                .frame(height: 8)
                .clipped()

                // Border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                    .frame(height: 8)
            }
        }
        .padding(.horizontal, BrutalistTheme.spacingL)
        .padding(.vertical, BrutalistTheme.spacingS)
        .background(BrutalistTheme.brutalistLightCyan)
    }
    
    // Changes color as you run out of requests (Brutalist Colors - Different from Terminal)
    var meterColor: Color {
        if percentage > 0.5 {
            return BrutalistTheme.brutalistCyan
        }
        if percentage > 0.2 {
            return BrutalistTheme.brutalistYellow
        }
        return BrutalistTheme.brutalistRed
    }
}

// MARK: - AI Chef Orb Visualization Component (State-Driven)
struct AIChefOrbVisualization: View {
    @EnvironmentObject var chatService: ChatService
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background Rings (Dynamic Color Based on State)
            Circle()
                .stroke(statusColor.opacity(0.3), lineWidth: 3)
                .frame(width: 180, height: 180)
                .scaleEffect(chatService.currentState == .thinking ? 1.2 : chatService.currentState == .speaking ? 1.15 : 1.0)
                .animation(
                    Animation.easeInOut(duration: chatService.currentState == .thinking ? 0.5 : 2.0)
                        .repeatForever(autoreverses: true),
                    value: chatService.currentState
                )
            
            Circle()
                .stroke(statusColor.opacity(0.5), lineWidth: 3)
                .frame(width: 140, height: 140)
                .scaleEffect(chatService.currentState == .thinking ? 1.15 : chatService.currentState == .speaking ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: chatService.currentState == .thinking ? 0.6 : 2.2)
                        .repeatForever(autoreverses: true),
                    value: chatService.currentState
                )
            
            // Main ring with breathing effect (Dynamic Color)
            Circle()
                .stroke(statusColor, lineWidth: 6)
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: animationDuration)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Inner white circle with brain icon (FIXED: Sandwich Method)
            ZStack {
                // Shadow
                Circle()
                    .fill(BrutalistTheme.brutalistBlack)
                    .frame(width: 70, height: 70)
                    .offset(x: 2, y: 2)
                
                // Fill
                Circle()
                    .fill(BrutalistTheme.brutalistWhite)
                    .frame(width: 70, height: 70)
                
                // Content - Brain Icon with Dynamic Rotation
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Border
                Circle()
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                    .frame(width: 70, height: 70)
            }
            .scaleEffect(pulseScale * 0.98)
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true),
                value: pulseScale
            )
        }
        .frame(height: 180)
        .onAppear {
            startAnimations()
        }
        .onChange(of: chatService.currentState) { _, _ in
            startAnimations()
        }
    }
    
    // MARK: - Computed Properties
    private var statusColor: Color {
        switch chatService.currentState {
        case .idle:
            return BrutalistTheme.brutalistCyan
        case .thinking:
            return BrutalistTheme.brutalistYellow
        case .speaking:
            return BrutalistTheme.brutalistLime
        }
    }
    
    private var animationDuration: Double {
        switch chatService.currentState {
        case .idle:
            return 2.0
        case .thinking:
            return 0.8
        case .speaking:
            return 1.2
        }
    }
    
    private var rotationSpeed: Double {
        switch chatService.currentState {
        case .idle:
            return 20.0
        case .thinking:
            return 2.0
        case .speaking:
            return 5.0
        }
    }
    
    private func startAnimations() {
        // Reset and start rotation
        rotationAngle = 0
        withAnimation(.linear(duration: rotationSpeed).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Reset and start pulse
        pulseScale = chatService.currentState == .thinking ? 1.15 : chatService.currentState == .speaking ? 1.1 : 1.08
        withAnimation(.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
            pulseScale = chatService.currentState == .thinking ? 1.25 : chatService.currentState == .speaking ? 1.15 : 1.0
        }
    }
}

// MARK: - Welcome Message Card Component (FIXED: Sandwich Method)
struct WelcomeMessageCard: View {
    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistBlack)
                .offset(x: 5, y: 5)
            
            // Fill
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .fill(BrutalistTheme.brutalistLavender)
            
            // Content
            VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                HStack {
                    Text("👋")
                        .font(.system(size: 32))
                    
                    Spacer()
                    
                    Text("AI CHEF")
                        .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                        .padding(.horizontal, BrutalistTheme.spacingS)
                        .padding(.vertical, 4)
                        .background(BrutalistTheme.brutalistYellow)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: 2)
                        )
                }
                
                Text("I'm your AI Chef assistant. I can help you with:")
                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                    FeatureRow(icon: "🍽️", text: "Recipe suggestions")
                    FeatureRow(icon: "📊", text: "Food waste analysis")
                    FeatureRow(icon: "⏰", text: "Expiry date tracking")
                    FeatureRow(icon: "🌱", text: "Sustainability tips")
                }
            }
            .padding(BrutalistTheme.spacingL)
            
            // Border
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: BrutalistTheme.spacingS) {
            Text(icon)
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: BrutalistTheme.bodySmall))
                .foregroundColor(BrutalistTheme.brutalistBlack)
        }
    }
}

// MARK: - Chat Message Bubble Component (FIXED: Sandwich Method)
struct ChatMessageBubble: View {
    let message: ChatService.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            ZStack {
                // Shadow
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: message.isUser ? -5 : 5, y: 5)
                
                // Fill
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(message.isUser ? BrutalistTheme.brutalistCyan : BrutalistTheme.brutalistWhite)
                
                // Content
                VStack(alignment: .leading, spacing: BrutalistTheme.spacingXS) {
                    // Label
                    Text(message.isUser ? "YOU" : "AI CHEF")
                        .font(.system(size: BrutalistTheme.caption, weight: BrutalistTheme.fontBlack, design: .monospaced))
                        .foregroundColor(message.isUser ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistCyan)
                    
                    // Message Text
                    Text(message.content)
                        .font(.system(size: BrutalistTheme.bodyMedium))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                }
                .padding(BrutalistTheme.spacingM)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .leading)
                
                // Border
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Typing Indicator Component (FIXED: Sandwich Method)
struct TypingIndicator: View {
    @State private var animatingDot = 0
    @State private var timer: Timer?

    var body: some View {
        HStack {
            ZStack {
                // Shadow
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistBlack)
                    .offset(x: 5, y: 5)
                
                // Fill
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .fill(BrutalistTheme.brutalistWhite)
                
                // Content
                HStack(spacing: BrutalistTheme.spacingS) {
                    Text("AI CHEF")
                        .font(.system(size: BrutalistTheme.caption, weight: BrutalistTheme.fontBlack, design: .monospaced))
                        .foregroundColor(BrutalistTheme.brutalistCyan)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(BrutalistTheme.brutalistBlack)
                                .frame(width: 8, height: 8)
                                .opacity(animatingDot == index ? 1.0 : 0.3)
                        }
                    }
                }
                .padding(BrutalistTheme.spacingM)
                
                // Border
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            }
            
            Spacer()
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation {
                    animatingDot = (animatingDot + 1) % 3
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

#Preview {
    AIOrbView()
        .environmentObject(ChatService())
        .environmentObject(HistoryStore())
}
