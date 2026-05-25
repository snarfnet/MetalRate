import SwiftUI

struct ContentView: View {
    @State private var service = MetalService()
    @State private var showJPY = true
    @State private var selectedCategory: MetalCategory?

    private var filteredMetals: [MetalInfo] {
        if let cat = selectedCategory {
            return service.metals.filter { $0.category == cat }
        }
        return service.metals
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    currencyToggle
                    categoryFilter
                    rateInfo

                    ForEach(filteredMetals) { metal in
                        MetalCard(metal: metal, showJPY: showJPY)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
        }
        .task {
            await service.fetchPrices()
        }
        .refreshable {
            await service.fetchPrices()
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("METAL RATE")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(Theme.gold)
                Text("金属相場")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                Task { await service.fetchPrices() }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 48, height: 48)
                    if service.isLoading {
                        ProgressView()
                            .tint(Theme.gold)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
    }

    private var currencyToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "JPY ¥", active: showJPY) { showJPY = true }
            toggleButton(title: "USD $", active: !showJPY) { showJPY = false }
        }
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func toggleButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(active ? .black : .white.opacity(0.5))
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(active ? Theme.gold : .clear, in: Capsule())
        }
    }

    private var categoryFilter: some View {
        HStack(spacing: 8) {
            catButton(title: "すべて", cat: nil)
            ForEach(MetalCategory.allCases, id: \.self) { cat in
                catButton(title: cat.rawValue, cat: cat)
            }
            Spacer()
        }
    }

    private func catButton(title: String, cat: MetalCategory?) -> some View {
        Button {
            selectedCategory = cat
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(selectedCategory == cat ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selectedCategory == cat ? Theme.gold : Color.white.opacity(0.06), in: Capsule())
        }
    }

    private var rateInfo: some View {
        HStack {
            if let date = service.lastUpdated {
                Text("更新: \(date.formatted(.dateTime.hour().minute()))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            Text("USD/JPY: \(service.usdJpy, specifier: "%.2f")")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.gold.opacity(0.7))
        }
    }
}

// MARK: - Metal Card

private struct MetalCard: View {
    let metal: MetalInfo
    let showJPY: Bool

    private var displayPrice: String {
        let price = showJPY ? metal.priceJPY : metal.priceUSD
        if price == 0 { return "--" }
        if price >= 1000 {
            return String(format: "%,.0f", price)
        } else if price >= 10 {
            return String(format: "%.2f", price)
        }
        return String(format: "%.4f", price)
    }

    private var currencySymbol: String {
        showJPY ? "¥" : "$"
    }

    private var metalColor: Color {
        switch metal.id {
        case "gold": return Color(red: 1.0, green: 0.84, blue: 0.0)
        case "silver": return Color(red: 0.75, green: 0.75, blue: 0.78)
        case "platinum": return Color(red: 0.88, green: 0.88, blue: 0.90)
        case "palladium": return Color(red: 0.72, green: 0.72, blue: 0.76)
        case "copper": return Color(red: 0.85, green: 0.55, blue: 0.30)
        case "aluminum": return Color(red: 0.80, green: 0.82, blue: 0.85)
        case "nickel": return Color(red: 0.65, green: 0.70, blue: 0.68)
        case "zinc": return Color(red: 0.60, green: 0.65, blue: 0.72)
        case "lead": return Color(red: 0.50, green: 0.50, blue: 0.55)
        case "tin": return Color(red: 0.75, green: 0.78, blue: 0.72)
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Metal icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(metalColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Text(metal.symbol)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(metalColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(metal.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text(metal.nameEn)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text(metal.category.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(metalColor.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(metalColor.opacity(0.1), in: Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 2) {
                    Text(currencySymbol)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.gold.opacity(0.7))
                    Text(displayPrice)
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Text("/ \(metal.unit)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(metalColor.opacity(0.12)))
    }
}

// MARK: - Theme

private enum Theme {
    static let bg = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}
