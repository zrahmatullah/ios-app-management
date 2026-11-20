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
    
    private var roundUpPreview: Int64? {
        guard let amt = Int64(amountString.replacingOccurrences(of: ".", with: "")), amt > 0 else { return nil }
        let remainder = amt % 5000
        if remainder == 0 { return 0 }
        return 5000 - remainder
    }
    
    public init(viewModel: FinanceViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Jenis Transaksi", selection: $txType) {
                        Text("Pengeluaran").tag("EXPENSE")
                        Text("Pemasukan").tag("INCOME")
                        Text("Transfer").tag("TRANSFER")
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text("Rp")
                            .font(LuminaFont.title2())
                            .foregroundColor(.secondary)
                        TextField("0", text: $amountString)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Akun & Kategori")) {
                    Picker("Dari Akun", selection: $selectedAccountId) {
                        Text("Pilih Akun").tag("")
                        ForEach(viewModel.accounts) { acc in
                            Text(acc.name).tag(acc.id)
                        }
                    }
                    
                    if txType == "TRANSFER" {
                        Picker("Ke Akun", selection: $selectedToAccountId) {
                            Text("Pilih Akun Tujuan").tag("")
                            ForEach(viewModel.accounts) { acc in
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
                    }
                }
                
                Section(header: Text("Detail")) {
                    DatePicker("Tanggal", selection: $txDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Catatan / Keterangan", text: $note)
                }
                
                if txType == "EXPENSE" {
                    Section(header: Text("Otomatisasi Celengan (Round-Up)")) {
                        Toggle("Bulatkan ke Celengan", isOn: $enableRoundUp)
                        if enableRoundUp {
                            HStack {
                                Text("Pembulatan ke")
                                Spacer()
                                Text("Kelipatan Rp 5.000")
                                    .foregroundColor(.secondary)
                            }
                            if let calculated = roundUpPreview {
                                HStack {
                                    Text("Selisih Ditabung")
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
                        saveTransaction()
                    }
                    .disabled(amountString.isEmpty || selectedAccountId.isEmpty)
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let firstAcc = viewModel.accounts.first {
                    selectedAccountId = firstAcc.id
                }
                if let firstCat = filteredCategories.first {
                    selectedCategoryId = firstCat.id
                }
            }
        }
    }
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == txType }
    }
    
    private func saveTransaction() {
        guard let amount = Int64(amountString.replacingOccurrences(of: ".", with: "")) else { return }
        
        let toAcc = txType == "TRANSFER" ? selectedToAccountId : nil
        let catId = txType != "TRANSFER" ? selectedCategoryId : nil
        
        Task {
            let success = await viewModel.createTransaction(
                accountId: selectedAccountId,
                toAccountId: toAcc,
                categoryId: catId,
                amount: amount,
                type: txType,
                note: note,
                date: txDate
            )
            if success {
                dismiss()
            }
        }
    }
}
