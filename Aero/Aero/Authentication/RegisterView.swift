import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var agreeToTerms: Bool = false
    @State private var glitchOffset: CGFloat = 0
    @State private var glitchTimer: Timer?
    
    private var isFormValid: Bool {
        let isEmailValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
        let isPasswordValid = password.count >= 6
        let isNameValid = !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isEmailValid && isPasswordValid && isNameValid && agreeToTerms
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F5").ignoresSafeArea()
            DottedPatternBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrutalistTheme.spacingXL) {
                    
                    // MARK: - Header
                    AuthHeaderComponent(
                        title: "Register",
                        subtitle: "Create your account to track your impact.",
                        showsBackButton: true,
                        backAction: {
                            authManager.clearError()
                            dismiss()
                        }
                    )
                    
                    // MARK: - Error Banner (FIXED: reads from authManager, not local state)
                    if let errorMsg = authManager.authError {
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 4, y: 4)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(errorMsg.hasPrefix("✅") ? Color.green.opacity(0.15) : BrutalistTheme.brutalistYellow)
                            Text(errorMsg)
                                .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .padding(BrutalistTheme.spacingM)
                                .frame(maxWidth: .infinity)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                        .padding(.horizontal, BrutalistTheme.spacingL)
                    }
                    
                    // MARK: - Hero Text
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingM) {
                        Text("Start Tracking.")
                            .font(.system(size: BrutalistTheme.titleHuge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 5, y: 5)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .fill(BrutalistTheme.brutalistBlack)
                            ZStack {
                                Text("Live Smarter.")
                                    .font(.system(size: BrutalistTheme.titleHuge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistRed.opacity(0.4))
                                    .offset(x: -glitchOffset * 2, y: -glitchOffset)
                                Text("Live Smarter.")
                                    .font(.system(size: BrutalistTheme.titleHuge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistCyan.opacity(0.4))
                                    .offset(x: glitchOffset * 2, y: glitchOffset)
                                Text("Live Smarter.")
                                    .font(.system(size: BrutalistTheme.titleHuge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistCyan)
                                    .offset(x: glitchOffset)
                            }
                            .padding(.horizontal, BrutalistTheme.spacingL)
                            .padding(.vertical, BrutalistTheme.spacingM)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusLarge)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    .onAppear {
                        glitchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            withAnimation(.linear(duration: 0.05)) {
                                glitchOffset = CGFloat.random(in: -2...2)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.linear(duration: 0.05)) { glitchOffset = 0 }
                            }
                        }
                    }
                    .onDisappear {
                        glitchTimer?.invalidate()
                        glitchTimer = nil
                    }
                    
                    // MARK: - Motivational Copy
                    HStack(alignment: .top, spacing: BrutalistTheme.spacingM) {
                        Rectangle()
                            .fill(BrutalistTheme.brutalistBlack)
                            .frame(width: 4, height: 40)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("Stop Wasting. Start Tracking. ")
                            Text("Proactive intervention")
                                .padding(.horizontal, 4)
                                .background(BrutalistTheme.brutalistYellow)
                            Text(" starts now.")
                        }
                        .font(.system(size: BrutalistTheme.bodyLarge, weight: .medium))
                        .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Form Fields
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                        // Full Name
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            Text("FULL NAME")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            TextField("e.g. Alex Sterling", text: $fullName)
                                .font(.system(size: BrutalistTheme.bodyLarge, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .disabled(authManager.isProcessing)
                                .padding(BrutalistTheme.spacingM)
                                .background(sandwichBackground())
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            Text("EMAIL ADDRESS")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            TextField("user@example.com", text: $email)
                                .font(.system(size: BrutalistTheme.bodyLarge, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .disabled(authManager.isProcessing)
                                .padding(BrutalistTheme.spacingM)
                                .background(sandwichBackground())
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            HStack {
                                Text("PASSWORD")
                                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .fill(BrutalistTheme.brutalistBlack).offset(x: 2, y: 2)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .fill(BrutalistTheme.brutalistYellow)
                                    Text("Min. 6 chars")
                                        .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .padding(.horizontal, BrutalistTheme.spacingS)
                                        .padding(.vertical, 4)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            }
                            HStack(spacing: BrutalistTheme.spacingM) {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .font(.system(size: BrutalistTheme.bodyLarge, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .disabled(authManager.isProcessing)
                                } else {
                                    SecureField("........", text: $password)
                                        .font(.system(size: BrutalistTheme.bodyLarge, design: .monospaced))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                        .disabled(authManager.isProcessing)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(BrutalistTheme.brutalistBlack)
                                }
                                .disabled(authManager.isProcessing)
                            }
                            .padding(BrutalistTheme.spacingM)
                            .background(sandwichBackground())
                        }
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Terms Checkbox
                    HStack(alignment: .top, spacing: BrutalistTheme.spacingM) {
                        Button(action: { agreeToTerms.toggle() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(agreeToTerms ? BrutalistTheme.brutalistBlack : BrutalistTheme.brutalistWhite)
                                    .frame(width: 24, height: 24)
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                    .frame(width: 24, height: 24)
                                if agreeToTerms {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(BrutalistTheme.brutalistWhite)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(authManager.isProcessing)
                        
                        (Text("I agree to the ") +
                         Text("Zero-Waste Policy").underline().foregroundColor(BrutalistTheme.brutalistRed) +
                         Text(" and Terms of Service."))
                            .font(.system(size: BrutalistTheme.bodyMedium))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Create Account Button
                    Button(action: {
                        Task {
                            await authManager.registerWithEmail(
                                email: email,
                                password: password,
                                fullName: fullName
                            )
                        }
                    }) {
                        HStack(spacing: BrutalistTheme.spacingM) {
                            if authManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: BrutalistTheme.brutalistBlack))
                            } else {
                                Text("CREATE ACCOUNT")
                                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(BrutalistButtonStyle(bgColor: isFormValid && !authManager.isProcessing ? BrutalistTheme.brutalistCyan : Color.gray))
                    .disabled(!isFormValid || authManager.isProcessing)
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    Spacer().frame(height: BrutalistTheme.spacingM)
                    
                    // MARK: - OR Divider
                    orDivider(label: "OR")
                    
                    // MARK: - Social Buttons
                    VStack(spacing: BrutalistTheme.spacingM) {
                        Button(action: {
                            Task { await authManager.signInWithGoogle() }
                        }) {
                            HStack(spacing: BrutalistTheme.spacingS) {
                                Image(systemName: "globe").font(.system(size: 20, weight: .bold))
                                Text("CONTINUE WITH GOOGLE")
                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            }
                        }
                        .buttonStyle(BrutalistButtonStyle(bgColor: authManager.isProcessing ? Color.gray : BrutalistTheme.brutalistWhite))
                        .disabled(authManager.isProcessing)
                        
                        Button(action: {
                            Task { await authManager.signInWithApple() }
                        }) {
                            HStack(spacing: BrutalistTheme.spacingS) {
                                Image(systemName: "applelogo").font(.system(size: 20, weight: .bold))
                                Text("CONTINUE WITH APPLE")
                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBlack, design: .monospaced))
                            }
                        }
                        .buttonStyle(BrutalistButtonStyle(bgColor: authManager.isProcessing ? Color.gray : BrutalistTheme.brutalistWhite))
                        .disabled(authManager.isProcessing)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Footer
                    HStack(spacing: BrutalistTheme.spacingXS) {
                        Text("Already tracking?")
                            .font(.system(size: BrutalistTheme.bodyMedium))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        Button(action: {
                            authManager.clearError()
                            dismiss()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistBlack).offset(x: 3, y: 3)
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .fill(BrutalistTheme.brutalistYellow)
                                Text("Log in")
                                    .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .padding(.horizontal, BrutalistTheme.spacingM)
                                    .padding(.vertical, BrutalistTheme.spacingS)
                                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                            }
                        }
                        .contentShape(Rectangle())
                        .disabled(authManager.isProcessing)
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    .padding(.vertical, BrutalistTheme.spacingXL)
                    
                    Spacer().frame(height: BrutalistTheme.spacingXL)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    // MARK: - Reusable Sub-Views
    
    @ViewBuilder
    private func sandwichBackground() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistBlack).offset(x: 4, y: 4)
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .fill(BrutalistTheme.brutalistWhite)
            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
        }
    }
    
    @ViewBuilder
    private func orDivider(label: String) -> some View {
        HStack(spacing: BrutalistTheme.spacingM) {
            Rectangle().fill(BrutalistTheme.brutalistBlack).frame(height: 2)
            ZStack {
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .fill(BrutalistTheme.brutalistBlack).offset(x: 3, y: 3)
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .fill(BrutalistTheme.brutalistWhite)
                Text(label)
                    .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                    .foregroundColor(BrutalistTheme.brutalistBlack)
                    .padding(.horizontal, BrutalistTheme.spacingM)
                    .padding(.vertical, BrutalistTheme.spacingXS)
                RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                    .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
            }
            Rectangle().fill(BrutalistTheme.brutalistBlack).frame(height: 2)
        }
        .padding(.horizontal, BrutalistTheme.spacingL)
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager(isPreviewMode: true))
}
