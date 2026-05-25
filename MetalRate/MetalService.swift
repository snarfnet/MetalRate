import Foundation
import Observation

struct MetalInfo: Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let symbol: String
    let icon: String
    let category: MetalCategory
    var priceUSD: Double = 0
    var priceJPY: Double = 0
    var unit: String = "oz"
}

enum MetalCategory: String, CaseIterable {
    case precious = "貴金属"
    case base = "ベースメタル"
}

@Observable
final class MetalService {
    var metals: [MetalInfo] = Self.defaultMetals()
    var lastUpdated: Date?
    var isLoading = false
    var errorMessage: String?
    var usdJpy: Double = 157.0

    private static func defaultMetals() -> [MetalInfo] {
        [
            MetalInfo(id: "gold", name: "金", nameEn: "Gold", symbol: "XAU", icon: "circle.fill", category: .precious),
            MetalInfo(id: "silver", name: "銀", nameEn: "Silver", symbol: "XAG", icon: "circle.fill", category: .precious),
            MetalInfo(id: "platinum", name: "プラチナ", nameEn: "Platinum", symbol: "XPT", icon: "circle.fill", category: .precious),
            MetalInfo(id: "palladium", name: "パラジウム", nameEn: "Palladium", symbol: "XPD", icon: "circle.fill", category: .precious),
            MetalInfo(id: "copper", name: "銅", nameEn: "Copper", symbol: "Cu", icon: "square.fill", category: .base, unit: "lb"),
            MetalInfo(id: "aluminum", name: "アルミニウム", nameEn: "Aluminum", symbol: "Al", icon: "square.fill", category: .base, unit: "lb"),
            MetalInfo(id: "nickel", name: "ニッケル", nameEn: "Nickel", symbol: "Ni", icon: "square.fill", category: .base, unit: "lb"),
            MetalInfo(id: "zinc", name: "亜鉛", nameEn: "Zinc", symbol: "Zn", icon: "square.fill", category: .base, unit: "lb"),
            MetalInfo(id: "lead", name: "鉛", nameEn: "Lead", symbol: "Pb", icon: "square.fill", category: .base, unit: "lb"),
            MetalInfo(id: "tin", name: "スズ", nameEn: "Tin", symbol: "Sn", icon: "square.fill", category: .base, unit: "lb"),
        ]
    }

    func fetchPrices() async {
        isLoading = true
        errorMessage = nil

        // Fetch USD/JPY rate
        await fetchUSDJPY()

        // Fetch metal prices from metals.dev
        do {
            let url = URL(string: "https://api.metals.dev/v1/latest?api_key=demo&currency=USD&unit=toz")!
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                // Fallback to sample data if API fails
                loadFallbackPrices()
                isLoading = false
                return
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let metalsData = json?["metals"] as? [String: Double] {
                updatePrices(from: metalsData)
            }
            lastUpdated = Date()
        } catch {
            loadFallbackPrices()
        }
        isLoading = false
    }

    private func fetchUSDJPY() async {
        do {
            let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let rates = json?["rates"] as? [String: Double], let jpy = rates["JPY"] {
                usdJpy = jpy
            }
        } catch {}
    }

    private func updatePrices(from data: [String: Double]) {
        let keyMap: [String: String] = [
            "gold": "gold", "silver": "silver", "platinum": "platinum", "palladium": "palladium",
            "copper": "copper", "aluminum": "aluminum", "nickel": "nickel",
            "zinc": "zinc", "lead": "lead", "tin": "tin",
        ]
        for i in metals.indices {
            if let key = keyMap[metals[i].id], let price = data[key] {
                metals[i].priceUSD = price
                metals[i].priceJPY = price * usdJpy
            }
        }
    }

    private func loadFallbackPrices() {
        // Approximate prices as of mid-2026 for demo/offline
        let fallback: [String: Double] = [
            "gold": 2650, "silver": 31.5, "platinum": 1020, "palladium": 980,
            "copper": 4.35, "aluminum": 1.15, "nickel": 7.80,
            "zinc": 1.25, "lead": 0.95, "tin": 14.50,
        ]
        for i in metals.indices {
            if let price = fallback[metals[i].id] {
                metals[i].priceUSD = price
                metals[i].priceJPY = price * usdJpy
            }
        }
        lastUpdated = Date()
        errorMessage = "オフラインデータを表示中"
    }
}
