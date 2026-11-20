import SwiftUI

public struct RegisterView: View {
    let onRegistrationComplete: () -> Void
    
    @State private var name: String = ""
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var errorMessage: String?
    
    public init(onRegistrationComplete: @escaping () -> Void) {
        self.onRegistrationComplete = onRegistrationComplete
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profil Pribadi")) {
                    TextField("Nama Panggilan Anda", text: $name)
                }
                
                Section(header: Text("Kunci Master (PIN 6 Digit)")) {
                    SecureField("Masukkan 6 Digit PIN", text: $passcode)
                        .keyboardType(.numberPad)
                    SecureField("Konfirmasi 6 Digit PIN", text: $confirmPasscode)
                        .keyboardType(.numberPad)
                }
                
                Section(footer: Text("Sesuai standar OWASP MASVS, PIN Anda di-hash dengan garam kriptografi acak (Salted SHA-256) dan disimpan aman di iOS Keychain. Data tidak pernah meninggalkan iPhone Anda.")) {
                    if let err = errorMessage {
                        Text(err)
                            .font(LuminaFont.caption())
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: register) {
                        HStack {
                            Spacer()
                            Text("Daftarkan Akun & Kunci Brankas")
                                .font(LuminaFont.headline())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(LuminaTheme.primaryGradient)
                    .disabled(name.isEmpty || passcode.count != 6 || confirmPasscode != passcode)
                }
            }
            .navigationTitle("Pendaftaran Akun")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func register() {
        guard passcode == confirmPasscode else {
            errorMessage = "PIN konfirmasi tidak cocok!"
            return
        }
        guard passcode.count == 6 else {
            errorMessage = "PIN harus 6 digit angka!"
            return
        }
        
        let success = SecurityManager.shared.registerMasterAccount(name: name, passcode: passcode)
        if success {
            HapticManager.notification(.success)
            onRegistrationComplete()
        } else {
            errorMessage = "Gagal mengamankan kunci di iOS Keychain."
        }
    }
}
