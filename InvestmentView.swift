import SwiftUI
import Charts

struct InvestmentView: View {

    @StateObject private var store = MarketStore()
    @State private var tradeStock: Stock?
    @AppStorage("market_username") private var username = ""
    @State private var showGate = false
    @State private var showAllSheet = false
    @State private var startCoach = false

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            CenteredScrollView(maxWidth: 640) {
                VStack(spacing: Theme.Space.l) {

                    header

                    marketSection

                    if !store.record.shares.isEmpty {
                        holdingsSection
                    }

                    leaderboardSection
                }
            }
        }
        .navigationTitle("Investing")
        .coachMarks(.investment, autoStart: !username.isEmpty, trigger: $startCoach)
        .onAppear {
            store.start()
            if username.isEmpty { showGate = true }
        }
        .onDisappear { store.stop() }
        .sheet(item: $tradeStock) { stock in
            TradeSheet(store: store, stock: stock)
        }
        .fullCover(isPresented: $showGate) {
            UsernameGateView(store: store) {
                showGate = false
                startCoach = true      // show the feature tour right after choosing a username
            }
        }
        .sheet(isPresented: $showAllSheet) {
            AllStocksSheet(store: store)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: Theme.Space.xs) {
            Text("Net Worth")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.6))
            Text("\(store.netWorth, specifier: "%.2f") 🐯")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Theme.teal)
            HStack(spacing: Theme.Space.m) {
                Label("\(store.record.stripes, specifier: "%.0f") stripes free", systemImage: "creditcard.fill")
                Label("\(store.holdingsValue, specifier: "%.0f") invested", systemImage: "chart.pie.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.ink.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .card()
        .tutorialAnchor("inv.header")
    }

    // MARK: Market

    private var marketSection: some View {
        let list = store.trendingStocks
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                SectionTitle("Trending 🔥")
                Spacer()
                Button("See all") { showAllSheet = true }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.teal)
                    .tutorialAnchor("inv.seeall")
            }
            ForEach(list) { stock in
                Button { tradeStock = stock } label: { stockRow(stock) }
                    .buttonStyle(.plain)
                if stock.id != list.last?.id { Divider() }
            }
        }
        .card()
        .tutorialAnchor("inv.market")
    }

    private func stockRow(_ stock: Stock) -> some View {
        let price = store.price(stock)
        let up = price >= store.priceEarlier(stock)
        let owned = store.shares(stock)
        return HStack(spacing: Theme.Space.s) {
            ZStack {
                Circle().fill(stock.color).frame(width: 44, height: 44)
                Image(systemName: stock.icon).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name).font(.headline).foregroundStyle(Theme.ink)
                Text(owned > 0 ? "You own \(String(format: "%.2f", owned)) shares" : stock.id)
                    .font(.caption)
                    .foregroundStyle(Theme.ink.opacity(0.55))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Label("\(stock.id)", systemImage: up ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption2.weight(.bold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(up ? Theme.secondary : Theme.coral)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: Holdings

    private var holdingsSection: some View {
        let held = Market.stocks.filter { store.shares($0) > 0 }
        let total = held.reduce(0.0) { $0 + store.shares($1) * store.price($1) }
        return VStack(alignment: .leading, spacing: Theme.Space.s) {
            SectionTitle("Your Portfolio")

            // Pie chart: how your money is split across stocks.
            Chart(held) { stock in
                SectorMark(
                    angle: .value("Value", store.shares(stock) * store.price(stock)),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(stock.color)
                .cornerRadius(4)
            }
            .frame(height: 180)

            ForEach(held) { stock in
                Button { tradeStock = stock } label: { holdingRow(stock, total: total) }
                    .buttonStyle(.plain)
                if stock.id != held.last?.id { Divider() }
            }

            Label("Tap a stock to sell it. Stocks have a 1-day hold before you can sell.",
                  systemImage: "hand.tap.fill")
                .font(.caption)
                .foregroundStyle(Theme.ink.opacity(0.55))
        }
        .card()
    }

    private func holdingRow(_ stock: Stock, total: Double) -> some View {
        let value = store.shares(stock) * store.price(stock)
        let pct = total > 0 ? value / total * 100 : 0
        return HStack(spacing: Theme.Space.s) {
            Circle().fill(stock.color).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name).fontWeight(.semibold).foregroundStyle(Theme.ink)
                Text("\(store.shares(stock), specifier: "%.2f") shares • \(pct, specifier: "%.0f")%")
                    .font(.caption).foregroundStyle(Theme.ink.opacity(0.55))
            }
            Spacer()
            Text("\(value, specifier: "%.2f")")
                .fontWeight(.bold).foregroundStyle(Theme.teal)
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(Theme.ink.opacity(0.3))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            SectionTitle("Leaderboard")
            if store.leaderboard.isEmpty {
                Text("Loading players…")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.s)
            } else {
                ForEach(Array(store.leaderboard.prefix(10).enumerated()), id: \.element.id) { rank, entry in
                    HStack(spacing: Theme.Space.s) {
                        Text(medal(rank))
                            .font(.headline)
                            .frame(width: 34)
                        Text(entry.name)
                            .fontWeight(entry.isMe ? .heavy : .semibold)
                            .foregroundStyle(Theme.ink)
                        if entry.isMe {
                            Text("You")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(Theme.teal.opacity(0.2), in: Capsule())
                                .foregroundStyle(Theme.teal)
                        }
                        Spacer()
                        Text("\(entry.worth, specifier: "%.0f") 🐯")
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.ink)
                    }
                    .padding(.vertical, 4)
                    .background(entry.isMe ? Theme.teal.opacity(0.08) : .clear,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .card()
        .tutorialAnchor("inv.leaderboard")
    }

    private func medal(_ rank: Int) -> String {
        switch rank {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(rank + 1)"
        }
    }
}

// MARK: - Trade sheet

private struct TradeSheet: View {
    @ObservedObject var store: MarketStore
    let stock: Stock

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var showChart = false
    @State private var range: ChartRange = .month

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            ScrollView {
                VStack(spacing: Theme.Space.m) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundStyle(Theme.ink.opacity(0.4))
                        }
                    }

                    ZStack {
                        Circle().fill(stock.color).frame(width: 76, height: 76)
                        Image(systemName: stock.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text(stock.name)
                        .font(.title.weight(.heavy)).foregroundStyle(Theme.ink)
                    Text(stock.id)
                        .font(.subheadline).foregroundStyle(Theme.ink.opacity(0.6))

                    Text("\(store.price(stock), specifier: "%.2f") stripes / share")
                        .font(.headline).foregroundStyle(Theme.teal)

                    Stepper("Shares: \(quantity)", value: $quantity, in: 1...max(1, maxBuyOrOwn))
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 4)

                    Text("Cost: \(Double(quantity) * store.price(stock), specifier: "%.2f") stripes")
                        .font(.subheadline).foregroundStyle(Theme.ink.opacity(0.7))

                    HStack(spacing: Theme.Space.s) {
                        Button("Sell") {
                            store.sell(stock, shares: Double(quantity))
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.coral))
                        .disabled(!canSellNow)
                        .opacity(canSellNow ? 1 : 0.5)

                        Button("Buy") {
                            store.buy(stock, shares: Double(quantity))
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary))
                        .disabled(Double(quantity) * store.price(stock) > store.record.stripes)
                        .opacity(Double(quantity) * store.price(stock) > store.record.stripes ? 0.5 : 1)
                    }

                    if store.shares(stock) == 0 {
                        Label("Heads up: after you buy, there's a 1-day hold before you can sell.",
                              systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.ink.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }

                    Text("You have \(store.record.stripes, specifier: "%.0f") stripes • own \(store.shares(stock), specifier: "%.2f")")
                        .font(.caption).foregroundStyle(Theme.ink.opacity(0.55))

                    if store.shares(stock) > 0 && !store.canSell(stock) {
                        Label("You can sell this in \(holdRemaining) — stocks have a 1-day hold.",
                              systemImage: "lock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.coral)
                            .multilineTextAlignment(.center)
                    }

                    Divider()

                    Button {
                        withAnimation { showChart.toggle() }
                    } label: {
                        Label(showChart ? "Hide trends" : "View trends", systemImage: "chart.xyaxis.line")
                    }
                    .buttonStyle(.bordered)
                    .tint(stock.color)

                    if showChart { trendChart }
                }
                .card(padding: Theme.Space.m)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
                .padding(Theme.Space.l)
            }
        }
        .presentationDetents([.large])
    }

    private var trendChart: some View {
        let points = Market.history(for: stock, ending: store.now, days: range.days, samples: range.samples)
        let first = points.first?.price ?? 0
        let last = points.last?.price ?? 0
        let pct = first > 0 ? (last - first) / first * 100 : 0
        return VStack(spacing: Theme.Space.s) {
            Picker("Range", selection: $range) {
                ForEach(ChartRange.allCases) { r in Text(r.rawValue).tag(r) }
            }
            .pickerStyle(.segmented)

            Text("\(range.label): \(pct >= 0 ? "+" : "")\(String(format: "%.1f", pct))%")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(pct >= 0 ? Theme.secondary : Theme.coral)

            Chart(points) { point in
                LineMark(x: .value("Day", point.date), y: .value("Price", point.price))
                    .foregroundStyle(stock.color)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Day", point.date), y: .value("Price", point.price))
                    .foregroundStyle(stock.color.opacity(0.12))
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 170)
        }
    }

    private var maxBuyOrOwn: Int {
        max(store.maxAffordable(stock), Int(store.shares(stock).rounded(.up)), 1)
    }

    private var canSellNow: Bool {
        store.canSell(stock) && store.shares(stock) >= Double(quantity)
    }

    private var holdRemaining: String {
        let s = Int(store.secondsUntilSellable(stock))
        let h = s / 3600, m = (s % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Chart range

enum ChartRange: String, CaseIterable, Identifiable {
    case week = "1W", month = "1M", year = "1Y"
    var id: String { rawValue }
    var days: Int { switch self { case .week: 7; case .month: 30; case .year: 365 } }
    var samples: Int { switch self { case .week: 28; case .month: 30; case .year: 60 } }
    var label: String { switch self { case .week: "This week"; case .month: "This month"; case .year: "This year" } }
}

// MARK: - All stocks (searchable popup)

private struct AllStocksSheet: View {
    @ObservedObject var store: MarketStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var tradeStock: Stock?

    private var filtered: [Stock] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Market.stocks }
        return Market.stocks.filter {
            $0.name.lowercased().contains(q)
            || $0.real.lowercased().contains(q)
            || $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { stock in
                Button { tradeStock = stock } label: { row(stock) }
                    .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("All Stocks")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $query, prompt: "Search a company (e.g. Netflix)")
        }
        .sheet(item: $tradeStock) { TradeSheet(store: store, stock: $0) }
    }

    private func row(_ stock: Stock) -> some View {
        let price = store.price(stock)
        let up = price >= store.priceEarlier(stock)
        return HStack(spacing: Theme.Space.s) {
            ZStack {
                Circle().fill(stock.color).frame(width: 40, height: 40)
                Image(systemName: stock.icon).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name).font(.headline).foregroundStyle(Theme.ink)
                Text(stock.id).font(.caption).foregroundStyle(Theme.ink.opacity(0.5))
            }
            Spacer()
            Text("\(price, specifier: "%.2f")").font(.headline).foregroundStyle(Theme.ink)
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(up ? Theme.secondary : Theme.coral)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Username gate (first run)

private struct UsernameGateView: View {
    @ObservedObject var store: MarketStore
    var onDone: () -> Void

    @AppStorage("market_username") private var savedUsername = ""
    @State private var step = 0
    @State private var input = ""
    @State private var checking = false
    @State private var takenError = false

    private let banned = ["idiot", "stupid", "dumb", "hate", "kill", "sexy", "nude", "loser", "damn"]

    private var formatError: String? {
        let t = input.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return nil }
        if t.count < 3 { return "Make it at least 3 characters." }
        if t.count > 15 { return "Keep it under 15 characters." }
        if t.contains(" ") { return "No spaces — pick one nickname." }
        if t.contains("@") || t.contains(".") { return "No emails or dots, please." }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        if t.rangeOfCharacter(from: allowed.inverted) != nil { return "Only letters, numbers, and _ allowed." }
        if banned.contains(where: { t.lowercased().contains($0) }) { return "Please pick a friendlier name." }
        return nil
    }

    private var isValid: Bool {
        input.trimmingCharacters(in: .whitespaces).count >= 3 && formatError == nil
    }

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            ScrollView {
                VStack(spacing: Theme.Space.m) {
                    Image("tiger")
                        .resizable().scaledToFit().frame(height: 90)
                        .accessibilityHidden(true)

                    if step == 0 { intro } else { usernameStep }
                }
                .card(padding: Theme.Space.m)
                .frame(maxWidth: 500)
                .frame(maxWidth: .infinity)
                .padding(Theme.Space.l)
            }
        }
        .interactiveDismissDisabled(true)
        .keyboardDoneButton()
    }

    private var intro: some View {
        VStack(spacing: Theme.Space.m) {
            Text("Welcome to the Tiger Market!")
                .font(.title2.weight(.heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: Theme.Space.s) {
                bullet("creditcard.fill", "Get 100 tiger stripes — game points, not real money!")
                bullet("chart.line.uptrend.xyaxis", "Buy tiger stocks — prices rise and fall live.")
                bullet("trophy.fill", "Compete and play with friends on the leaderboard!")
            }

            Button("Next") { withAnimation { step = 1 } }
                .buttonStyle(PrimaryButtonStyle(fill: Theme.teal))
        }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: icon).foregroundStyle(Theme.teal).frame(width: 28)
            Text(text).font(.subheadline).foregroundStyle(Theme.ink.opacity(0.8))
            Spacer(minLength: 0)
        }
    }

    private var usernameStep: some View {
        VStack(spacing: Theme.Space.s) {
            Text("Pick a username")
                .font(.title2.weight(.heavy))
                .foregroundStyle(Theme.ink)

            Label("Don't use your real name or any personal info — pick a fun nickname!",
                  systemImage: "exclamationmark.shield.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.coral)
                .multilineTextAlignment(.leading)

            KidTextField(placeholder: "e.g. StripeyPro7", text: $input)

            if let err = formatError {
                Text(err).font(.caption.weight(.semibold)).foregroundStyle(Theme.coral)
            } else if takenError {
                Text("That username is already taken — try another!")
                    .font(.caption.weight(.semibold)).foregroundStyle(Theme.coral)
            }

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: Theme.Space.xs) {
                    if checking { ProgressView().tint(.white) }
                    Text(checking ? "Checking…" : "Let's go!")
                }
            }
            .buttonStyle(PrimaryButtonStyle(fill: Theme.teal))
            .disabled(!isValid || checking)
            .opacity(isValid && !checking ? 1 : 0.5)

            Button("Back") { withAnimation { step = 0 } }
                .font(.subheadline)
                .foregroundStyle(Theme.ink.opacity(0.5))
        }
    }

    @MainActor
    private func submit() async {
        takenError = false
        guard isValid else { return }
        let name = input.trimmingCharacters(in: .whitespaces)
        checking = true
        let taken = await store.usernameTaken(name)
        checking = false
        if taken { takenError = true; return }
        store.setUsername(name)
        savedUsername = name
        onDone()
    }
}
