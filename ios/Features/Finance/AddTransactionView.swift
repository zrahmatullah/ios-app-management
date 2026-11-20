import SwiftUI

public struct AddTransactionView: View {
    @ObservedObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var txType: String = "EXPENSE"
    @State private var amountString: String = ""
    @State private var selectedAccountId: String = ""
    @State private var selectedToAccountId: String = ""
    @State private var selectedCategoryId: String = ""
    @State private var note: String = ""
    @State private var txDate: Date = Date()
    @State private var enableRoundUp: Bool = false
    @State private var showInsufficientBalanceAlert: Bool = false
    
    private var numericAmount: Int64 {
        Int64(amountString.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var selectedAccount: Account? {
        viewModel.accounts.first { $0.id == selectedAccountId }
    }
    
    private var selectedCategory: Category? {
        viewModel.categories.first { $0.id == selectedCategoryId }
    }
    
    private var matchingBudget: Budget? {
        guard let cat = selectedCategory else { return nil }
        return viewModel.budgets.first { $0.categoryId == cat.id }
    }
    
    private var isOverBudgetWarning: Bool {
        guard txType == "EXPENSE", let b = matchingBudget else { return false }
        return (b.spent + numericAmount) > b.amount
    }
    
    private var isBalanceInsufficient: Bool {
        guard txType != "INCOME", let acc = selectedAccount else { return false }
        return numericAmount > acc.balance
    }
    
    private var roundUpPreview: Int64? {
        guard numericAmount > 0 else { return nil }
        let remainder = numericAmount % 5000
        if remainder == 0 { return 0 }
        return 5000 - remainder
    }
    
    private var isFormValid: Bool {
        guard numericAmount > 0, !selectedAccountId.isEmpty else { return false }
        if txType == "TRANSFER" {
            return !selectedToAccountId.isEmpty && selectedToAccountId != selectedAccountId
        } else {
            return !selectedCategoryId.isEmpty
        }
    }
    
    public init(viewModel: FinanceViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Transaction Type & Amount
                Section {
                    Picker("Jenis Transaksi", selection: $txType) {
                        Text("Pengeluaran").tag("EXPENSE")
                        Text("Pemasukan").tag("INCOME")
                        Text("Transfer").tag("TRANSFER")
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Rp")
                                .font(LuminaFont.title2().weight(.semibold))
                                .foregroundColor(.secondary)
                            TextField("0", text: $amountString)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                        }
                        
                        // Quick Amount Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickAmountButton(10000, label: "+10rb")
                                quickAmountButton(50000, label: "+50rb")
                                quickAmountButton(100000, label: "+100rb")
                                quickAmountButton(500000, label: "+500rb")
                                Button("Reset") {
                                    amountString = ""
                                    HapticManager.impact(.light)
                                }
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // Account Selection & Balance Indicator
                Section(header: Text("Akun")) {
                    Picker("Dari Akun", selection: $selectedAccountId) {
                        Text("Pilih Akun Sumber").tag("")
                        ForEach(viewModel.accounts) { acc in
                            HStack {
                                Text(acc.name)
                                Spacer()
                                Text("Rp \(acc.balance.formatted())")
                                    .foregroundColor(.secondary)
                            }
                            .tag(acc.id)
                        }
                    }
                    
                    if let acc = selectedAccount {
                        HStack {
                            Text("Saldo Saat Ini")
                                .font(LuminaFont.caption())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Rp \(acc.balance.formatted())")
                                .font(LuminaFont.caption().weight(.bold))
                                .foregroundColor(isBalanceInsufficient ? .red : .primary)
                        }
                        
                        if isBalanceInsufficient {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Saldo akun tidak mencukupi untuk transaksi ini.")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if txType == "TRANSFER" {
                        Picker("Ke Akun Tujuan", selection: $selectedToAccountId) {
                            Text("Pilih Akun Tujuan").tag("")
                            ForEach(viewModel.accounts.filter { $0.id != selectedAccountId }) { acc in
                                Text(acc.name).tag(acc.id)
                            }
                        }
                    } else {
                        Picker("Kategori", selection: $selectedCategoryId) {
                            Text("Pilih Kategori").tag("")
                            ForEach(filteredCategories) { cat in
                                Text(cat.name).tag(cat.id)
                            }
                        }
                        
                        // Budget warning if applicable
                        if let b = matchingBudget {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Anggaran Kategori")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Sisa: Rp \((b.amount - b.spent).formatted())")
                                        .font(LuminaFont.caption().weight(.bold))
                                        .foregroundColor(isOverBudgetWarning ? .red : Color(hex: "10B981"))
                                }
                                
                                if isOverBudgetWarning {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(Color(hex: "F43F5E"))
                                        Text("Transaksi ini akan melebihi anggaran bulanan kategori ini!")
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(Color(hex: "F43F5E"))
                                    }
                                }
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                
                // Transaction Details
                Section(header: Text("Detail")) {
                    DatePicker("Tanggal", selection: $txDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Catatan / Keterangan (Opsional)", text: $note)
                }
                
                // Round-up Savings Automation
                if txType == "EXPENSE" {
                    Section(header: Text("Otomatisasi Celengan (Round-Up)")) {
                        Toggle("Bulatkan ke Celengan", isOn: $enableRoundUp)
                        if enableRoundUp {
                            HStack {
                                Text("Aturan Pembulatan")
                                Spacer()
                                Text("Kelipatan Rp 5.000")
                                    .foregroundColor(.secondary)
                            }
                            if let calculated = roundUpPreview {
                                HStack {
                                    Text("Koin Ditabung ke Celengan")
                                    Spacer()
                                    Text("+Rp \(calculated.formatted())")
                                        .font(LuminaFont.subheadline().weight(.bold))
                                        .foregroundColor(Color(hex: "10B981"))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Tambah Transaksi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        if isBalanceInsufficient {
                            showInsufficientBalanceAlert = true
                        } else {
                            saveTransaction()
                        }
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.bold)
                }
            }
            .alert("Peringatan Saldo", isPresented: $showInsufficientBalanceAlert) {
                Button("Lanjutkan Tetap Simpan", role: .destructive) {
                    saveTransaction()
                }
                Button("Periksa Kembali", role: .cancel) {}
            } message: {
                Text("Saldo akun sumber tidak mencukupi untuk pengeluaran ini. Apakah Anda yakin ingin melanjutkan?")
            }
            .onAppear {
                if let firstAcc = viewModel.accounts.first, selectedAccountId.isEmpty {
                    selectedAccountId = firstAcc.id
                }
                if let firstCat = filteredCategories.first, selectedCategoryId.isEmpty {
                    selectedCategoryId = firstCat.id
                }
            }
            .onChange(of: txType) { newType in
                if let firstCat = viewModel.categories.first(where: { $0.type == newType }) {
                    selectedCategoryId = firstCat.id
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == txType }
    }
    
    private func quickAmountButton(_ addAmount: Int64, label: String) -> some View {
        Button(action: {
            let current = numericAmount
            amountString = "\(current + addAmount)"
            HapticManager.impact(.light)
        }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "6366F1"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "6366F1").opacity(0.12))
                .cornerRadius(8)
        }
    }
    
    private func saveTransaction() {
        guard numericAmount > 0 else { return }
        
        let toAcc = txType == "TRANSFER" ? selectedToAccountId : nil
        let catId = txType != "TRANSFER" ? selectedCategoryId : nil
        
        Task {
            let success = await viewModel.createTransaction(
                accountId: selectedAccountId,
                toAccountId: toAcc,
                categoryId: catId,
                amount: numericAmount,
                type: txType,
                note: note,
                date: txDate
            )
            if success {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}
