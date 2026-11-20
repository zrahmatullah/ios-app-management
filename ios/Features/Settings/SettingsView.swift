import SwiftUI

public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Keamanan
                Section(header: Text("Keamanan & Privasi")) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isBiometricEnabled },
                        set: { val in
                            Task { await viewModel.toggleBiometric(enable: val) }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .foregroundColor(Color(hex: "6366F1"))
                            Text("Kunci Aplikasi (Face ID / Passcode)")
                        }
                    }
                }
                
                // Tampilan & Tema
                Section(header: Text("Tampilan & Tema")) {
                    Picker("Tema Aplikasi", selection: $viewModel.appTheme) {
                        Text("Otomatis (Sistem)").tag("auto")
                        Text("Terang (Light)").tag("light")
                        Text("Gelap (Dark)").tag("dark")
                    }
                    
                    Picker("Warna Aksen", selection: $viewModel.accentColor) {
                        Text("Indigo").tag("indigo")
                        Text("Violet").tag("violet")
                        Text("Emerald").tag("emerald")
                        Text("Rose").tag("rose")
                    }
                }
                
                // Backup & Restore
                Section(header: Text("Cadangan & Data Lokal")) {
                    Button(action: {
                        Task { await viewModel.exportBackupJson() }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(Color(hex: "007AFF"))
                            Text("Ekspor Cadangan Lengkap (JSON)")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        Task { await viewModel.exportTransactionsCSV() }
                    }) {
                        HStack {
                            Image(systemName: "tablecells")
                                .foregroundColor(Color(hex: "10B981"))
                            Text("Ekspor Transaksi (CSV)")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Info Aplikasi
                Section(header: Text("Tentang Lumina")) {
                    Button(action: {
                        UserDefaults.standard.set(false, forKey: "lumina_has_seen_welcome")
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color(hex: "6366F1"))
                            Text("Buka Kembali Halaman Sambutan")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Versi")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Penyimpanan")
                        Spacer()
                        Text("SQLite Lokal (Offline-first)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status Akun")
                        Spacer()
                        Text("Tanpa Akun (100% Privat)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Pengaturan")
            .sheet(isPresented: $viewModel.showingShareSheet) {
                ActivityView(activityItems: viewModel.shareItems)
            }
        }
    }
}

// MARK: - UIActivityViewController SwiftUI Bridge
public struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
