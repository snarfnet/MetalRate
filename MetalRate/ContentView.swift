import SwiftUI

struct ContentView: View {
    @State private var service = MetalService()
    @State private var showJPY = true
    @State private var selectedCategory: MetalCategory?

    private var filteredMetals: [MetalInfo] {
        if let selectedCategory {
            return service.metals.filter { $0.category == selectedCategory }
        }
        return service.metals
    }

    var body: some View {
        ZStack {
            MetalBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    marketStrip
                    currencyToggle
                    categoryFilter

                    ForEach(filteredMetals) { metal in
                        MetalCard(metal: metal, showJPY: showJPY)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 80)
            }
        }
        .task { await service.fetchPrices() }
        .refreshable { await service.fetchPrices() }
        .safeAreaInset(edge: .bottom) {
            AdMobBannerView(adUnitID: AdMobConfig.bannerAdUnitID)
                .background(.black.opacity(0.84))
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("METAL RATE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Theme.gold)
                Text("金属相場")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.white)
                Text("貴金属と産業金属の価格をすばやく確認")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            Spacer()
            Button {
                Task { await service.fetchPrices() }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.10))
                        .frame(width: 50, height: 50)
                    if service.isLoading {
                        ProgressView().tint(Theme.gold)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
        .padding(18)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.10)))
    }

    private var marketStrip: some View {
        HStack {
            if let date = service.lastUpdated {
                Label(date.formatted(.dateTime.hour().minute()), systemImage: "clock")
            } else {
                Label("取得待ち", systemImage: "clock")
            }
            Spacer()
            Text("USD/JPY \(service.usdJpy, specifier: "%.2f")")
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.62))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.07), in: Capsule())
    }

    private var currencyToggle: some View {
        HStack(spacing: 0) {
            toggleButton(title: "JPY ¥", active: showJPY) { showJPY = true }
            toggleButton(title: "USD $", active: !showJPY) { showJPY = false }
        }
        .background(.white.opacity(0.08), in: Capsule())
    }

    private func toggleButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(active ? .black : .white.opacity(0.55))
                .frame(maxWidth: .infinity, minHeight: 40)
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
                .foregroundStyle(selectedCategory == cat ? .black : .white.opacity(0.58))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selectedCategory == cat ? Theme.gold : .white.opacity(0.08), in: Capsule())
        }
    }
}

private struct MetalCard: View {
    let metal: MetalInfo
    let showJPY: Bool

    private var displayPrice: String {
        let price = showJPY ? metal.priceJPY : metal.priceUSD
        if price == 0 { return "--" }
        if price >= 1000 { return String(format: "%,.0f", price) }
        if price >= 10 { return String(format: "%.2f", price) }
        return String(format: "%.4f", price)
    }

    private var currencySymbol: String {
        showJPY ? "¥" : "$"
    }

    private var metalColor: Color {
        switch metal.id {
        case "gold": return Color(red: 1.0, green: 0.82, blue: 0.18)
        case "silver": return Color(red: 0.78, green: 0.80, blue: 0.84)
        case "platinum": return Color(red: 0.88, green: 0.90, blue: 0.92)
        case "palladium": return Color(red: 0.68, green: 0.72, blue: 0.78)
        case "copper": return Color(red: 0.92, green: 0.52, blue: 0.27)
        default: return Color(red: 0.62, green: 0.70, blue: 0.72)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(metalColor.opacity(0.16))
                    .frame(width: 56, height: 56)
                Text(metal.symbol)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(metalColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(metal.name)
                        .font(.system(size: 18, weight: .bold))
                    Text(metal.nameEn)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.42))
                }
                Text(metal.category.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(metalColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(metalColor.opacity(0.12), in: Capsule())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(currencySymbol)\(displayPrice)")
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                Text("/ \(metal.unit)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.38))
            }
        }
        .foregroundStyle(.white)
        .padding(15)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(metalColor.opacity(0.24)))
    }
}

private struct MetalBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.055).ignoresSafeArea()
            Image("HeroArtwork")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.44)
            LinearGradient(colors: [.black.opacity(0.06), .black.opacity(0.86)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}

private enum Theme {
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.22)
}
