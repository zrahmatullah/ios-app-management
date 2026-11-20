import SwiftUI

public struct SavingsDetailView: View {
    let savings: Savings
    @ObservedObject var viewModel: SavingsViewModel
    
    @State private var showingDepositSheet: Bool = false
    @State private var entryType: String = "DEPOSIT" // DEPOSIT or WITHDRAW
    
    public init(savings: Savings, viewModel: SavingsViewModel) {
        self.savings = savings
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Progress Card
                LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 24) {
                    VStack(spacing: 16) {
                        LuminaProgressRing(
                            progress: savings.progress,
                            lineWidth: 14,
                            gradient: LuminaTheme.savingsGradient,
                            showLabel: true
                        )
                        .frame(width: 120, height: 120)
                        
                        VStack(spacing: 6) {
                            Text(savings.name)
                                .font(LuminaFont.title2())
                            HStack {
                                LuminaAmountText(amount: savings.currentAmount, font: LuminaFont.title3().weight(.bold))
                                Text("/")
                                LuminaAmountText(amount: savings.targetAmount, font: LuminaFont.subheadline())
                            }
                        }
                        
                        // Action Buttons: Setor / Tarik
                        HStack(spacing: 14) {
                            LuminaButton("Setor Dana", icon: "plus", gradient: LuminaTheme.incomeGradient) {
                                entryType = "DEPOSIT"
                                showingDepositSheet = true
                            }
                            
                            LuminaButton("Tarik Dana", icon: "minus", gradient: LuminaTheme.expenseGradient) {
                                entryType = "WITHDRAW"
                                showingDepositSheet = true
                            }
                        }
                    }
                }
                
                // Smart Projections & Recommendations
                if let proj = viewModel.selectedProjection {
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text("Saran & Proyeksi Cerdas")
                                    .font(LuminaFont.headline())
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sisa Hari")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    Text("\(proj.daysRemaining) hari")
                                        .font(LuminaFont.headline())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Saran per Bulan")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    LuminaAmountText(amount: proj.recommendedMonthlyDeposit, font: LuminaFont.headline())
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Saran per Minggu")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    LuminaAmountText(amount: proj.recommendedWeeklyDeposit, font: LuminaFont.subheadline())
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Saran per Hari")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    LuminaAmountText(amount: proj.recommendedDailyDeposit, font: LuminaFont.subheadline())
                                }
                            }
                            
                            if let est = proj.estimatedCompletionDate {
                                HStack {
                                    Text("Estimasi Tercapai:")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(est.formatted(date: .long, time: .omitted))
                                        .font(LuminaFont.caption().weight(.bold))
                                        .foregroundColor(Color(hex: "10B981"))
                                }
                            }
                        }
                    }
                }
                
                // Entry History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Riwayat Setoran & Penarikan")
                        .font(LuminaFont.headline())
                    
                    if !viewModel.entries.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(viewModel.entries) { entry in
                                LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                                    HStack {
                                        Image(systemName: entry.type == "DEPOSIT" ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                                            .foregroundColor(entry.type == "DEPOSIT" ? Color(hex: "10B981") : Color(hex: "F43F5E"))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.note.isEmpty ? (entry.type == "DEPOSIT" ? "Setoran Tabungan" : "Penarikan Tabungan") : entry.note)
                                                .font(LuminaFont.subheadline().weight(.medium))
                                            Text(entry.entryDate.formatted(date: .numeric, time: .shortened))
                                                .font(LuminaFont.caption())
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        LuminaAmountText(
                                            amount: entry.amount,
                                            type: entry.type == "DEPOSIT" ? "INCOME" : "EXPENSE",
                                            font: LuminaFont.headline()
                                        )
                                    }
                                }
                            }
                        }
                    } else {
                        Text("Belum ada riwayat setoran.")
                            .font(LuminaFont.subheadline())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(savings.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDepositSheet) {
            DepositSheetView(savingsId: savings.id, initialType: entryType, viewModel: viewModel)
        }
        .task {
            await viewModel.loadDetails(savingsId: savings.id)
        }
    }
}

// MARK: - Deposit & Withdraw Sheet
public struct DepositSheetView: View {
    let savingsId: String
    let initialType: String
    @ObservedObject var viewModel: SavingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: String = "DEPOSIT"
    @State private var amountString: String = ""
    @State private var selectedAccountId: String = ""
    @State private var note: String = ""
    @State private var validationError: String? = nil
    
    public init(savingsId: String, initialType: String, viewModel: SavingsViewModel) {
        self.savingsId = savingsId
        self.initialType = initialType
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Jenis", selection: $type) {
                        Text("Setor").tag("DEPOSIT")
                        Text("Tarik").tag("WITHDRAW")
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Rp")
                            .font(LuminaFont.title2())
                            .foregroundColor(.secondary)
                        TextField("0", text: $amountString)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .keyboardType(.numberPad)
                    }
                    
                    if let err = validationError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(err)
                                .font(LuminaFont.caption())
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Sumber Dana (Opsional)")) {
                    Picker("Hubungkan ke Dompet", selection: $selectedAccountId) {
                        Text("Tanpa Akun (Manual)").tag("")
                        ForEach(viewModel.accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                }
                
                Section(header: Text("Keterangan")) {
                    TextField("Catatan", text: $note)
                }
            }
            .navigationTitle(type == "DEPOSIT" ? "Setor ke Celengan" : "Tarik dari Celengan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveEntry()
                    }
                    .disabled(amountString.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                type = initialType
                if let firstAcc = viewModel.accounts.first {
                    selectedAccountId = firstAcc.id
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let amount = Int64(amountString.replacingOccurrences(of: ".", with: "")), amount > 0 else {
            validationError = "Nominal harus lebih dari Rp 0"
            return
        }
        
        if let s = viewModel.selectedSavings, type == "WITHDRAW", amount > s.currentAmount {
            validationError = "Penarikan melebihi saldo celengan (Rp \(s.currentAmount.formatted()))"
            HapticManager.notification(.error)
            return
        }
        
        Task {
            let accId = selectedAccountId.isEmpty ? nil : selectedAccountId
            let success = await viewModel.addEntry(
                savingsId: savingsId,
                accountId: accId,
                amount: amount,
                type: type,
                note: note
            )
            if success {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}
