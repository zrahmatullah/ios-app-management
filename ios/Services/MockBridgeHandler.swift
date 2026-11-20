import Foundation

// MARK: - Mock Fallback Handler for Xcode Preview & Local Development
public enum MockBridgeHandler {
    public static func mockDispatch<T: Decodable>(action: String) throws -> T {
        let json: String
        
        switch action {
        case "get_dashboard_summary":
            json = """
            {
                "total_balance": 5750000,
                "month_income": 8500000,
                "month_expense": 3200000,
                "top_savings": [
                    {"id": "s1", "name": "Dana Darurat", "target_amount": 15000000, "current_amount": 4500000, "deadline": "2026-12-31T00:00:00Z", "icon": "shield.checkerboard", "color": "#34C759", "status": "ACTIVE"}
                ],
                "top_goals": [
                    {"id": "g1", "title": "Sertifikasi Cloud Architect", "category": "CAREER", "deadline": "2026-11-30T00:00:00Z", "priority": "HIGH", "status": "ACTIVE", "progress": 0.65}
                ],
                "today_events": [
                    {"id": "e1", "title": "Evaluasi Budget Bulanan", "start_time": "2026-11-18T19:00:00Z", "end_time": "2026-11-18T20:00:00Z", "location": "Rumah", "color": "#5856D6", "reminder_minutes": 15, "is_completed": false}
                ],
                "recent_notes": [
                    {"id": "n1", "title": "Refleksi Mingguan", "content": "Progress tabungan sesuai rencana, perlu kurangi makan di luar.", "mood": "😊", "is_pinned": true, "is_archived": false, "note_date": "2026-11-18T00:00:00Z"}
                ],
                "recent_transactions": [
                    {"id": "t1", "account_id": "acc-bank", "account_name": "BCA Utama", "amount": 45000, "type": "EXPENSE", "category_name": "Makanan & Minuman", "category_icon": "fork.knife", "category_color": "#FF9500", "note": "Kopi Pagi", "transaction_date": "2026-11-18T08:30:00Z"}
                ],
                "habits_today": [
                    {"id": "h1", "title": "Minum Air 2L", "frequency": "DAILY", "streak_current": 4, "streak_longest": 12, "icon": "drop.fill", "color": "#007AFF", "is_done_today": true}
                ]
            }
            """
        case "list_accounts":
            json = """
            [
                {"id": "acc-cash", "name": "Uang Tunai", "type": "CASH", "balance": 500000, "currency": "IDR", "color": "#34C759", "icon": "banknotes.fill", "is_archived": false},
                {"id": "acc-bank", "name": "BCA Utama", "type": "BANK", "balance": 5000000, "currency": "IDR", "color": "#007AFF", "icon": "building.columns.fill", "is_archived": false},
                {"id": "acc-ewallet", "name": "GoPay", "type": "EWALLET", "balance": 250000, "currency": "IDR", "color": "#AF52DE", "icon": "creditcard.fill", "is_archived": false}
            ]
            """
        case "list_categories":
            json = """
            [
                {"id": "cat-inc-1", "name": "Gaji Pokok", "type": "INCOME", "icon": "briefcase.fill", "color": "#34C759", "is_default": true},
                {"id": "cat-exp-1", "name": "Makanan & Minuman", "type": "EXPENSE", "icon": "fork.knife", "color": "#FF9500", "is_default": true},
                {"id": "cat-exp-2", "name": "Belanja Kebutuhan", "type": "EXPENSE", "icon": "bag.fill", "color": "#FF2D55", "is_default": true},
                {"id": "cat-exp-3", "name": "Transportasi", "type": "EXPENSE", "icon": "car.fill", "color": "#007AFF", "is_default": true}
            ]
            """
        case "filter_transactions":
            json = """
            [
                {"id": "t1", "account_id": "acc-bank", "account_name": "BCA Utama", "amount": 45000, "type": "EXPENSE", "category_name": "Makanan & Minuman", "category_icon": "fork.knife", "category_color": "#FF9500", "note": "Kopi Pagi", "transaction_date": "2026-11-18T08:30:00Z"},
                {"id": "t2", "account_id": "acc-cash", "account_name": "Uang Tunai", "amount": 120000, "type": "EXPENSE", "category_name": "Belanja Kebutuhan", "category_icon": "bag.fill", "category_color": "#FF2D55", "note": "Minimarket", "transaction_date": "2026-11-17T14:15:00Z"}
            ]
            """
        case "list_savings":
            json = """
            [
                {"id": "s1", "name": "Dana Darurat", "target_amount": 15000000, "current_amount": 4500000, "deadline": "2026-12-31T00:00:00Z", "icon": "shield.checkerboard", "color": "#34C759", "status": "ACTIVE"},
                {"id": "s2", "name": "Liburan Akhir Tahun", "target_amount": 5000000, "current_amount": 2500000, "deadline": "2026-12-20T00:00:00Z", "icon": "airplane", "color": "#007AFF", "status": "ACTIVE"}
            ]
            """
        case "list_goals":
            json = """
            [
                {"id": "g1", "title": "Sertifikasi Cloud Architect", "category": "CAREER", "deadline": "2026-12-15T00:00:00Z", "priority": "HIGH", "status": "ACTIVE", "progress": 0.65},
                {"id": "g2", "title": "Lari 5K Nonstop", "category": "HEALTH", "deadline": "2026-11-30T00:00:00Z", "priority": "MEDIUM", "status": "ACTIVE", "progress": 0.40}
            ]
            """
        case "list_habits":
            json = """
            [
                {"id": "h1", "title": "Minum Air 2L", "frequency": "DAILY", "streak_current": 4, "streak_longest": 12, "icon": "drop.fill", "color": "#007AFF", "is_done_today": true},
                {"id": "h2", "title": "Membaca Buku 15 Menit", "frequency": "DAILY", "streak_current": 7, "streak_longest": 14, "icon": "book.fill", "color": "#AF52DE", "is_done_today": false}
            ]
            """
        case "list_events":
            json = """
            [
                {"id": "e1", "title": "Evaluasi Budget Bulanan", "start_time": "2026-11-18T19:00:00Z", "end_time": "2026-11-18T20:00:00Z", "location": "Rumah", "color": "#5856D6", "reminder_minutes": 15, "is_completed": false}
            ]
            """
        case "list_notes":
            json = """
            [
                {"id": "n1", "title": "Refleksi Mingguan", "content": "Progress tabungan sesuai rencana, perlu kurangi makan di luar.", "mood": "😊", "is_pinned": true, "is_archived": false, "note_date": "2026-11-18T00:00:00Z", "tags": ["Keuangan", "Refleksi"]}
            ]
            """
        case "get_settings":
            json = """
            {"currency": "IDR", "currency_symbol": "Rp", "language": "id", "theme": "auto", "biometric_locked": "false"}
            """
        default:
            json = "true"
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = json.data(using: .utf8) else {
            throw GoBridgeError.decodingError("Invalid mock JSON string")
        }
        return try decoder.decode(T.self, from: data)
    }
}
