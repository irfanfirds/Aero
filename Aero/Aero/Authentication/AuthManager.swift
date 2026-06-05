import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import UIKit
import Combine

@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var isProcessing: Bool = false
    @Published var authError: String?
    @Published var user: User?

    // MARK: - Private Properties
    private var currentNonce: String?
    private var handler: AuthStateDidChangeListenerHandle?
    private let isPreviewMode: Bool
    private var activeAppleSignInDelegate: AppleSignInDelegate?

    // MARK: - Initializers

    init() {
        self.isPreviewMode = false
        setupAuthListener()
    }

    init(isPreviewMode: Bool) {
        self.isPreviewMode = isPreviewMode
        if !isPreviewMode {
            setupAuthListener()
        }
    }

    // MARK: - Auth State Listener
    // Automatically keeps isLoggedIn in sync with Firebase's session state.
    // This means if the user was previously logged in, they stay logged in on relaunch.

    private func setupAuthListener() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                if let user = user {
                    // OAuth providers (Google, Apple) are inherently verified by their identity system.
                    // Email/password accounts require explicit email verification before gaining access.
                    let providerIDs = user.providerData.map { $0.providerID }
                    let isOAuth = providerIDs.contains("google.com") || providerIDs.contains("apple.com")
                    self?.isLoggedIn = isOAuth || user.isEmailVerified
                } else {
                    self?.isLoggedIn = false
                }
            }
        }
    }

    // MARK: - Clear Error

    func clearError() {
        authError = nil
    }

    // MARK: - Timeout Helper
    // Uses detached tasks to avoid MainActor deadlock with Firebase's async bridging.
    // Both the Firebase call and the timer run off the main actor completely.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval = 30,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let gate = TimeoutGate<T>()

            Task.detached(priority: .userInitiated) {
                do {
                    let result = try await operation()
                    gate.resume(continuation, with: .success(result))
                } catch {
                    gate.resume(continuation, with: .failure(error))
                }
            }

            Task.detached {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                gate.resume(continuation, with: .failure(URLError(.timedOut)))
            }
        }
    }

    // MARK: - Email Registration

    func registerWithEmail(email: String, password: String, fullName: String? = nil) async {
        authError = nil

        guard validateEmail(email) else {
            authError = "Please enter a valid email address."
            return
        }
        guard validatePassword(password) else {
            authError = "Password must be at least 6 characters long."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        if isPreviewMode {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            authError = "Preview Mode: Registration successful!"
            return
        }

        do {
            let result = try await withTimeout {
                try await Auth.auth().createUser(withEmail: email, password: password)
            }

            if let name = fullName, !name.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }

            try await result.user.sendEmailVerification()
            try Auth.auth().signOut()
            self.user = nil
            self.isLoggedIn = false
            authError = "✅ Account created! Check your email to verify before logging in."

        } catch {
            print("DEBUG: Firebase Auth failed with error: \(error)")
            authError = mapFirebaseError(error)
        }
    }

    // MARK: - Email Login

    func signInWithEmail(email: String, password: String) async {
        authError = nil

        guard validateEmail(email) else {
            authError = "Please enter a valid email address."
            return
        }
        guard !password.isEmpty else {
            authError = "Please enter your password."
            return
        }

        isProcessing = true
        defer {
            print("AUTH_TRACE: signInWithEmail ending — isProcessing → false")
            isProcessing = false
        }

        if isPreviewMode {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoggedIn = true
            return
        }

        print("AUTH_TRACE: calling Firebase signIn...")
        do {
            let result = try await withTimeout {
                try await Auth.auth().signIn(withEmail: email, password: password)
            }
            print("AUTH_TRACE: Firebase signIn returned, emailVerified=\(result.user.isEmailVerified)")
            if result.user.isEmailVerified {
                self.user = result.user
                self.isLoggedIn = true
            } else {
                try? Auth.auth().signOut()
                authError = "Email not verified. Check your inbox and click the verification link, then try again."
            }
        } catch {
            print("AUTH_TRACE: signIn error — \(error)")
            authError = mapFirebaseError(error)
        }
    }

    // MARK: - Forgot Password

    func sendPasswordReset(email: String) async {
        authError = nil

        guard validateEmail(email) else {
            authError = "Enter a valid email to receive a reset link."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            try await withTimeout { try await Auth.auth().sendPasswordReset(withEmail: email) }
            authError = "✅ Reset link sent — check your inbox."
        } catch {
            print("DEBUG: Firebase Auth failed with error: \(error)")
            authError = mapFirebaseError(error)
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        authError = nil
        isProcessing = true
        defer { isProcessing = false }

        if isPreviewMode {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoggedIn = true
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            authError = "Firebase configuration error: missing Client ID."
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            authError = "Unable to present sign-in screen."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootVC,
                hint: nil,
                additionalScopes: []
            )

            guard let idToken = result.user.idToken?.tokenString else {
                authError = "Google Sign-In failed: missing token."
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            self.isLoggedIn = true

        } catch {
            let nsError = error as NSError
            // Code -5 = user cancelled the Google sign-in sheet — no error needed
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                return
            }
            print("DEBUG: Firebase Auth failed with error: \(error)")
            authError = mapFirebaseError(error)
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple() async {
        authError = nil
        isProcessing = true
        defer { isProcessing = false }

        if isPreviewMode {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoggedIn = true
            return
        }

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        do {
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate()
            self.activeAppleSignInDelegate = delegate
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            try await delegate.perform(controller)

            guard let appleCredential = delegate.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8),
                  let verifiedNonce = currentNonce else {
                authError = "Apple Sign-In failed: missing credentials."
                return
            }

            let firebaseCredential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idTokenString,
                rawNonce: verifiedNonce
            )

            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            self.user = authResult.user
            self.isLoggedIn = true
            self.activeAppleSignInDelegate = nil

        } catch {
            self.activeAppleSignInDelegate = nil
            print("DEBUG: Firebase Auth failed with error: \(error)")
            authError = mapFirebaseError(error)
        }
    }

    // MARK: - Logout

    func logout() {
        guard !isPreviewMode else {
            isLoggedIn = false
            user = nil
            authError = nil
            return
        }

        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut() // Also clear Google session
            user = nil
            isLoggedIn = false
            authError = nil
        } catch {
            authError = "Logout failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Validation

    private func validateEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex)
            .evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }

    private func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    // MARK: - Firebase Error Mapping

    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError

        if let urlError = error as? URLError, urlError.code == .timedOut {
            return "Connection timed out. Check your internet and try again."
        }

        print("DEBUG: Firebase Error Domain: \(nsError.domain), Code: \(nsError.code), Description: \(nsError.localizedDescription)")
        
        // Handle specific Firebase Auth error codes
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        
        switch code {
        case .invalidEmail:
            return "Invalid email address format."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .userNotFound:
            return "No account found with this email."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled."
        case .operationNotAllowed:
            return "This sign-in method is not enabled."
        // --- NEW: Handle potential App Check errors explicitly ---
        case .appNotAuthorized:
            return "App not authorized. Please check your App Check configuration."
        default:
            return error.localizedDescription
        }
    }
    
    
    // MARK: - Crypto Helpers (required for Apple Sign-In)

    private func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &random) == errSecSuccess else { continue }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    deinit {
        if let handler { Auth.auth().removeStateDidChangeListener(handler) }
    }
}

// MARK: - TimeoutGate (resume-once guard for withTimeout)

private final class TimeoutGate<T>: @unchecked Sendable {
    private var resumed = false
    private let lock = NSLock()

    func resume(_ continuation: CheckedContinuation<T, Error>, with result: Result<T, Error>) {
        lock.lock()
        defer { lock.unlock() }
        guard !resumed else { return }
        resumed = true
        switch result {
        case .success(let value): continuation.resume(returning: value)
        case .failure(let error): continuation.resume(throwing: error)
        }
    }
}

// MARK: - Apple Sign-In Delegate

final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private(set) var credential: ASAuthorizationCredential?
    private var continuation: CheckedContinuation<Void, Error>?

    func perform(_ controller: ASAuthorizationController) async throws {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        credential = authorization.credential
        continuation?.resume()
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
