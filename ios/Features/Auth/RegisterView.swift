import SwiftUI

public struct RegisterView: View {
    let onRegistrationComplete: () -> Void
    
    @State private var name: String = ""
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var errorMessage: String?
    @State private var showConfirmPasscode: Bool = false
    
    public init(onRegistrationComplete: @escaping () -> Void) {
        self.onRegistrationComplete = onRegistrationComplete
    }
    
    // OWASP Validation Checks
    private var isNameValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }
    
    private var isPasscodeLengthValid: Bool {
        passcode.count == 6 && passcode.allSatisfy { $0.isNumber }
    }
    
    private var isPasscodeNonSequential: Bool {
        guard isPasscodeLengthValid else { return false }
        let sequential = ["012345", "123456", "234567", "345678", "456789", "543210", "654321", "765432", "876543", "987654"]
        let repeating = ["000000", "111111", "222222", "333333", "444444", "555555", "666666", "777777", "888888", "999999"]
        return !sequential.contains(passcode) && !repeating.contains(passcode)
    }
    
    private var isPasscodeMatching: Bool {
        !passcode.isEmpty && passcode == confirmPasscode
    }
    
    private var isFormValid: Bool {
        isNameValid && isPasscodeLengthValid && isPasscodeNonSequential && isPasscodeMatching
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profil Pribadi")) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 24)
                        TextField("Nama Panggilan Anda", text: $name)
                            .autocorrectionDisabled()
                        if isNameValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section(header: Text("Kunci Master (PIN 6 Digit)")) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 24)
                        SecureField("Masukkan 6 Digit PIN", text: $passcode)
                            .keyboardType(.numberPad)
                            .onChange(of: passcode) { newValue in
                                if newValue.count > 6 {
                                    passcode = String(newValue.prefix(6))
                                }
                            }
                        if isPasscodeLengthValid && isPasscodeNonSequential {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "lock.rotation")
                            .foregroundColor(Color(hex: "6366F1"))
                            .frame(width: 24)
                        if showConfirmPasscode {
                            TextField("Konfirmasi 6 Digit PIN", text: $confirmPasscode)
                                .keyboardType(.numberPad)
                        } else {
                            SecureField("Konfirmasi 6 Digit PIN", text: $confirmPasscode)
                                .keyboardType(.numberPad)
                        }
                        Button(action: { showConfirmPasscode.toggle() }) {
                            Image(systemName: showConfirmPasscode ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        if isPasscodeMatching {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section(header: Text("Standar Keamanan OWASP MASVS")) {
                    VStack(alignment: .leading, spacing: 8) {
                        validationRow(
                            title: "Nama minimal 3 karakter",
                            isValid: isNameValid
                        )
                        validationRow(
                            title: "PIN terdiri dari 6 angka",
                            isValid: isPasscodeLengthValid
                        )
                        validationRow(
                            title: "PIN tidak berupa urutan (123456) atau angka sama (111111)",
                            isValid: isPasscodeNonSequential
                        )
                        validationRow(
                            title: "Konfirmasi PIN cocok",
                            isValid: isPasscodeMatching
                        )
                    }
                    .padding(.vertical, 4)
                }
                
                Section(footer: Text("Sesuai standar OWASP MASVS, PIN Anda di-hash dengan garam kriptografi acak (Salted SHA-256) dan disimpan aman di iOS Keychain dengan proteksi biometrik. Data 100% offline dan tidak pernah keluar dari perangkat Anda.")) {
                    if let err = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(LuminaFont.caption())
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button(action: register) {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.shield.fill")
                            Text("Daftarkan Akun & Kunci Brankas")
                                .font(LuminaFont.headline())
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(
                        isFormValid
                            ? LuminaTheme.primaryGradient
                            : LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Pendaftaran Akun")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func validationRow(title: String, isValid: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary.opacity(0.6))
                .font(.system(size: 14))
            Text(title)
                .font(LuminaFont.caption())
                .foregroundColor(isValid ? .primary : .secondary)
        }
    }
    
    private func register() {
        guard isFormValid else {
            errorMessage = "Pastikan semua kriteria keamanan terpenuhi!"
            HapticManager.notification(.error)
            return
        }
        
        let success = SecurityManager.shared.registerMasterAccount(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            passcode: passcode
        )
        if success {
            HapticManager.notification(.success)
            onRegistrationComplete()
        } else {
            errorMessage = "Gagal mengamankan kunci di iOS Keychain."
            HapticManager.notification(.error)
        }
    }
}
