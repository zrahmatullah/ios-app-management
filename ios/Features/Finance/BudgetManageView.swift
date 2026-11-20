import SwiftUI

public struct BudgetManageView: View {
    @ObservedObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryId: String = ""
    @State private var amountString: String = ""
    @State private var alertThreshold: Double = 0.8
    
    private var numericAmount: Int64 {
        Int64(amountString.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var isFormValid: Bool {
        !selectedCategoryId.isEmpty && numericAmount > 0
    }
    
    public init(viewModel: FinanceViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tambah Anggaran Baru")) {
                    Picker("Kategori Pengeluaran", selection: $selectedCategoryId) {
                        Text("Pilih Kategori").tag("")
                        ForEach(viewModel.categories.filter { $0.type == "EXPENSE" }) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Batas (Rp)")
                                .font(LuminaFont.subheadline().weight(.medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("0", text: $amountString)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        // Quick amount chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickAmountButton(500000, label: "+500rb")
                                quickAmountButton(1000000, label: "+1jt")
                                quickAmountButton(2000000, label: "+2jt")
                                quickAmountButton(5000000, label: "+5jt")
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Peringatan saat pemakaian mencapai:")
                            Spacer()
                            Text("\(Int(alertThreshold * 100))%")
                                .fontWeight(.bold)
                                .foregroundColor(alertThreshold > 0.85 ? .red : .orange)
                        }
                        Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                    }
                    
                    Button(action: saveBudget) {
                        HStack {
                            Spacer()
                            Text("Simpan Anggaran")
                                .font(LuminaFont.headline())
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)
                }
                
                Section(header: Text("Daftar Anggaran Aktif")) {
                    if viewModel.budgets.isEmpty {
                        Text("Belum ada anggaran yang ditetapkan.")
                            .font(LuminaFont.caption())
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.budgets) { b in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(b.categoryName ?? "Kategori")
                                        .font(LuminaFont.headline())
                                    Text("Peringatan di \(Int(b.alertThreshold * 100))% • Terpakai: Rp \(b.spent.formatted())")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(b.spent > b.amount ? .red : .secondary)
                                }
                                Spacer()
                                LuminaAmountText(amount: b.amount, font: LuminaFont.subheadline())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Kelola Anggaran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Selesai") { dismiss() }
                }
            }
        }
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
    
    private func saveBudget() {
        guard isFormValid else { return }
        Task {
            let payload: [String: Any] = [
                "category_id": selectedCategoryId,
                "amount": numericAmount,
                "period": "MONTHLY",
                "start_date": ISO8601DateFormatter().string(from: Date()),
                "alert_threshold": alertThreshold
            ]
            let _: Budget = try await GoBridgeService.shared.dispatch(action: "save_budget", payload: payload)
            await viewModel.loadData()
            selectedCategoryId = ""
            amountString = ""
            HapticManager.notification(.success)
        }
    }
}
