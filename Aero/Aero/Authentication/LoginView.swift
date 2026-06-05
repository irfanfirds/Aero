import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var highlightRotation: Double = -3.5
    @State private var highlightOffset: CGFloat = 0
    @State private var showRegister: Bool = false
    
    private var isFormValid: Bool {
        let isEmailValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
        let isPasswordValid = password.count >= 6
        return isEmailValid && isPasswordValid
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F5")
                .ignoresSafeArea()
            
            DottedPatternBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: BrutalistTheme.spacingXL) {
                    
                    // MARK: - Header/Branding
                    VStack(spacing: BrutalistTheme.spacingL) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(BrutalistTheme.brutalistYellow)
                                .frame(width: 280, height: 70)
                                .offset(x: highlightOffset, y: 8)
                                .rotationEffect(.degrees(highlightRotation))
                                .opacity(0.85)
                                .animation(
                                    Animation.easeInOut(duration: 2.0)
                                        .repeatForever(autoreverses: true),
                                    value: highlightOffset
                                )
                            
                            Text("Aero")
                                .font(.system(size: 96, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .tracking(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, BrutalistTheme.spacingXL * 2)
                        .padding(.leading, BrutalistTheme.spacingL)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                highlightOffset = 8
                            }
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                highlightRotation = -2.5
                            }
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistBlack)
                                .offset(x: 5, y: 5)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .fill(BrutalistTheme.brutalistYellow)
                            Text("Log in to track your impact.")
                                .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                                .padding(BrutalistTheme.spacingL)
                                .frame(maxWidth: .infinity)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                        }
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Error Banner
                    if let errorMsg = authManager.authError {
                        Text(errorMsg)
                            .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBold, design: .monospaced))
                            .foregroundColor(errorMsg.hasPrefix("✅") ? .green : .red)
                            .padding(BrutalistTheme.spacingM)
                            .frame(maxWidth: .infinity)
                            .background(BrutalistTheme.brutalistWhite)
                            .border(errorMsg.hasPrefix("✅") ? Color.green : Color.red, width: BrutalistTheme.borderWidth)
                            .padding(.horizontal, BrutalistTheme.spacingL)
                    }
                    
                    // MARK: - Form Fields
                    VStack(alignment: .leading, spacing: BrutalistTheme.spacingL) {
                        // Email
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            Text("EMAIL ADDRESS")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
                            HStack(spacing: BrutalistTheme.spacingM) {
                                TextField("user@example.com", text: $email)
                                    .font(.system(size: BrutalistTheme.bodyLarge, design: .monospaced))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .disabled(authManager.isProcessing)
                                
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(BrutalistTheme.brutalistBlack)
                            }
                            .padding(BrutalistTheme.spacingM)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 4, y: 4)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistWhite)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            )
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: BrutalistTheme.spacingS) {
                            Text("PASSWORD")
                                .font(.system(size: BrutalistTheme.bodySmall, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                .foregroundColor(BrutalistTheme.brutalistBlack)
                            
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
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistBlack)
                                        .offset(x: 4, y: 4)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .fill(BrutalistTheme.brutalistWhite)
                                    RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusMedium)
                                        .stroke(BrutalistTheme.brutalistBlack, lineWidth: BrutalistTheme.borderWidth)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Login Button
                    Button(action: {
                        Task {
                            await authManager.signInWithEmail(email: email, password: password)
                        }
                    }) {
                        HStack(spacing: BrutalistTheme.spacingM) {
                            if authManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: BrutalistTheme.brutalistBlack))
                            } else {
                                Text("LOGIN")
                                    .font(.system(size: BrutalistTheme.bodyLarge, weight: BrutalistTheme.fontBlack, design: .monospaced))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(BrutalistButtonStyle(bgColor: isFormValid && !authManager.isProcessing ? BrutalistTheme.brutalistCyan : Color.gray))
                    .disabled(!isFormValid || authManager.isProcessing)
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Forgot Password (FIXED: now actually sends reset email)
                    Button(action: {
                        Task {
                            await authManager.sendPasswordReset(email: email)
                        }
                    }) {
                        Text("Forgot Password?")
                            .font(.system(size: BrutalistTheme.bodyMedium, weight: .medium))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                            .underline()
                    }
                    .disabled(authManager.isProcessing)
                    .padding(.top, BrutalistTheme.spacingS)
                    
                    // MARK: - OR Divider
                    HStack(spacing: BrutalistTheme.spacingM) {
                        Rectangle().fill(BrutalistTheme.brutalistBlack).frame(height: 2)
                        ZStack {
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .fill(BrutalistTheme.brutalistBlack).offset(x: 3, y: 3)
                            RoundedRectangle(cornerRadius: BrutalistTheme.cornerRadiusSmall)
                                .fill(BrutalistTheme.brutalistWhite)
                            Text("OR")
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
                    
                    // MARK: - Google Button
                    Button(action: {
                        Task { await authManager.signInWithGoogle() }
                    }) {
                        HStack(spacing: BrutalistTheme.spacingS) {
                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .bold))
                            Text("GOOGLE")
                                .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBlack, design: .monospaced))
                        }
                    }
                    .buttonStyle(BrutalistButtonStyle(bgColor: authManager.isProcessing ? Color.gray : BrutalistTheme.brutalistWhite))
                    .disabled(authManager.isProcessing)
                    .padding(.horizontal, BrutalistTheme.spacingL)
                    
                    // MARK: - Register Link
                    HStack(spacing: BrutalistTheme.spacingXS) {
                        Text("Don't have an account?")
                            .font(.system(size: BrutalistTheme.bodyMedium))
                            .foregroundColor(BrutalistTheme.brutalistBlack)
                        
                        Button(action: {
                            authManager.clearError()
                            showRegister = true
                        }) {
                            Text("Create Account")
                                .font(.system(size: BrutalistTheme.bodyMedium, weight: BrutalistTheme.fontBold))
                                .foregroundColor(BrutalistTheme.brutalistCyan)
                                .underline()
                        }
                        .disabled(authManager.isProcessing)
                    }
                    .padding(.vertical, BrutalistTheme.spacingXL)
                    
                    Spacer().frame(height: BrutalistTheme.spacingXL)
                }
            }
        }
        // FIXED: clearError() on dismiss so stale errors don't bleed between screens
        .sheet(isPresented: $showRegister, onDismiss: {
            authManager.clearError()
        }) {
            RegisterView()
                .environmentObject(authManager)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager(isPreviewMode: true))
}
