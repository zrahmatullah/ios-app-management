import SwiftUI

@main
struct LuminaApp: App {
    @AppStorage("lumina_theme") private var appTheme: String = "auto"
    @AppStorage("lumina_biometric_enabled") private var isBiometricEnabled: Bool = false
    @AppStorage("lumina_has_seen_welcome") private var hasSeenWelcome: Bool = false
    
    @State private var isDatabaseReady: Bool = false
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isRegistered: Bool = SecurityManager.shared.isAccountRegistered
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isDatabaseReady {
                    // Initial Splash Loading Screen
                    SplashLoadingView()
                        .transition(.opacity)
                } else if !isRegistered {
                    // OWASP MASVS-AUTH: Master Account Registration
                    RegisterView {
                        withAnimation(.spring()) {
                            isRegistered = true
                        }
                    }
                    .transition(.opacity)
                } else if !authViewModel.isUnlocked {
                    // OWASP MASVS-AUTH: Master Login Keypad with Brute-Force Throttling
                    LoginView(viewModel: authViewModel)
                        .transition(.opacity)
                } else if !hasSeenWelcome {
                    // Welcome & Onboarding Screen before Dashboard
                    WelcomeView {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            hasSeenWelcome = true
                        }
                    }
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading)))
                } else {
                    // Main Dashboard & Navigation
                    LuminaRootView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }
            .enableSecurityShield() // OWASP Privacy Shield against app switcher snapshotting
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isDatabaseReady)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isRegistered)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: authViewModel.isUnlocked)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: hasSeenWelcome)
            .preferredColorScheme(colorScheme)
            .task {
                await initializeCoreEngine()
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    authViewModel.isUnlocked = false
                }
            }
        }
    }
    
    private func initializeCoreEngine() async {
        do {
            try await GoBridgeService.shared.initialize()
            // Graceful micro-delay for smooth transition
            try? await Task.sleep(nanoseconds: 700_000_000)
            isDatabaseReady = true
        } catch {
            print("[LuminaApp] Go Core init error: \(error)")
            isDatabaseReady = true
        }
        
        // Schedule daily notification
        NotificationService.shared.scheduleDailyReviewReminder()
    }
    
    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Splash Loading Screen
struct SplashLoadingView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                LuminaPulsingSpinner()
                
                VStack(spacing: 6) {
                    Text("Lumina")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LuminaTheme.primaryGradient)
                    
                    Text("Menyiapkan basis data lokal...")
                        .font(LuminaFont.caption())
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
