import SwiftUI

public struct BudgetManageView: View {
    @ObservedObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryId: String = ""
    @State private var amountString: String = ""
    @State private var alertThreshold: Double = 0.8
    
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
                    
                    HStack {
                        Text("Batas (Rp)")
                        Spacer()
                        TextField("0", text: $amountString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Peringatan saat mencapai:")
                            Spacer()
                            Text("\(Int(alertThreshold * 100))%")
                                .fontWeight(.bold)
                        }
                        Slider(value: $alertThreshold, in: 0.5...1.0, step: 0.05)
                    }
                    
                    Button("Simpan Anggaran") {
                        saveBudget()
                    }
                    .disabled(selectedCategoryId.isEmpty || amountString.isEmpty)
                }
                
                Section(header: Text("Daftar Anggaran Aktif")) {
                    ForEach(viewModel.budgets) { b in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(b.categoryName ?? "Kategori")
                                    .font(LuminaFont.headline())
                                Text("Peringatan di \(Int(b.alertThreshold * 100))%")
                                    .font(LuminaFont.caption())
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            LuminaAmountText(amount: b.amount, font: LuminaFont.subheadline())
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
    
    private func saveBudget() {
        guard let amount = Int64(amountString.replacingOccurrences(of: ".", with: "")) else { return }
        Task {
            let payload: [String: Any] = [
                "category_id": selectedCategoryId,
                "amount": amount,
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
