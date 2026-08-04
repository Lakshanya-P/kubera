import SwiftUI

// MARK: - Configuration

enum MarketConfig {
    /// To let players on different devices compete, create a free Firebase
    /// Realtime Database (in test mode) and paste its URL here, e.g.
    /// "https://your-project-default-rtdb.firebaseio.com".
    /// Leave `nil` to play on a single device (with practice bots).
    static let backendURL: String? = "https://kubera-2d6bd-default-rtdb.firebaseio.com"

    static let startingStripes: Double = 100
}

/// Stripes earned from banking lessons wait here until the market next loads,
/// then get added to the player's balance.
enum StripeBank {
    private static let key = "pendingStripeReward"

    static func grant(_ amount: Double) {
        let d = UserDefaults.standard
        d.set(d.double(forKey: key) + amount, forKey: key)
    }

    static func claimPending() -> Double {
        let d = UserDefaults.standard
        let v = d.double(forKey: key)
        if v != 0 { d.set(0, forKey: key) }
        return v
    }
}

// MARK: - Stocks (tiger-punny replicas of real companies)

struct Stock: Identifiable, Hashable {
    let id: String        // ticker
    let name: String      // punny name
    let real: String      // real company it parodies (used for search only)
    let icon: String
    let colorHex: String
    let basePrice: Double
    let seed: Double
    let trend: Double     // real-world-ish direction: + rising, - falling

    var color: Color { Color.fromHex(colorHex) }
}

struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

enum Market {

    // Trends roughly mirror how each real company has been doing recently.
    static let stocks: [Stock] = [
        Stock(id: "GRL", name: "Googrowl",            real: "Google Alphabet",       icon: "magnifyingglass",                   colorHex: "#FF6B6B", basePrice: 28, seed: 2.3, trend: 0.6),
        Stock(id: "PMZ", name: "Pawmazon",            real: "Amazon",                icon: "shippingbox.fill",                  colorHex: "#FFB020", basePrice: 22, seed: 3.1, trend: 0.5),
        Stock(id: "TGS", name: "Tesclaw",             real: "Tesla",                 icon: "bolt.car.fill",                     colorHex: "#34C796", basePrice: 40, seed: 4.7, trend: -0.3),
        Stock(id: "NPX", name: "Netpurrix",           real: "Netflix",               icon: "play.rectangle.fill",               colorHex: "#8E7CFF", basePrice: 18, seed: 5.2, trend: 0.7),
        Stock(id: "PVD", name: "Purrvidia",           real: "Nvidia",                icon: "cpu.fill",                          colorHex: "#0FB5AE", basePrice: 30, seed: 6.6, trend: 1.0),
        Stock(id: "MEW", name: "Meowta",              real: "Meta Facebook",         icon: "bubble.left.and.bubble.right.fill", colorHex: "#4C6EF5", basePrice: 15, seed: 7.9, trend: 0.8),
        Stock(id: "WSK", name: "Meowsoft",            real: "Microsoft",             icon: "square.grid.2x2.fill",              colorHex: "#12B886", basePrice: 26, seed: 8.4, trend: 0.6),
        Stock(id: "TTK", name: "TigerTok",            real: "TikTok",                icon: "music.note",                        colorHex: "#EF476F", basePrice: 20, seed: 9.1, trend: 0.1),
        Stock(id: "UFR", name: "Ufur",                real: "Uber",                  icon: "car.fill",                          colorHex: "#2B2D42", basePrice: 24, seed: 10.3, trend: 0.6),
        Stock(id: "RBX", name: "Roarblox",            real: "Roblox",                icon: "cube.fill",                         colorHex: "#E63946", basePrice: 19, seed: 11.2, trend: 0.4),
        Stock(id: "SPF", name: "Spotifur",            real: "Spotify",               icon: "music.note.list",                   colorHex: "#1DB954", basePrice: 21, seed: 12.6, trend: 0.7),
        Stock(id: "PPL", name: "PawPal",              real: "PayPal",                icon: "creditcard.fill",                   colorHex: "#1C64F2", basePrice: 27, seed: 13.4, trend: -0.4),
        Stock(id: "SNC", name: "SnapClaw",            real: "Snap Snapchat",         icon: "camera.fill",                       colorHex: "#F4C430", basePrice: 16, seed: 14.8, trend: -0.5),
        Stock(id: "RCL", name: "Roaracle",            real: "Oracle",                icon: "server.rack",                       colorHex: "#C74634", basePrice: 31, seed: 15.2, trend: 0.6),
        Stock(id: "JPM", name: "JPMorgrran",          real: "JPMorgan Chase",        icon: "building.columns.fill",             colorHex: "#2E4A62", basePrice: 45, seed: 16.7, trend: 0.4),
        Stock(id: "GMS", name: "Goldmane Sacks",      real: "Goldman Sachs",         icon: "banknote.fill",                     colorHex: "#C99700", basePrice: 48, seed: 17.1, trend: 0.4),
        Stock(id: "THW", name: "Tigershire Hathaway", real: "Berkshire Hathaway",    icon: "chart.line.uptrend.xyaxis",         colorHex: "#1B4965", basePrice: 55, seed: 18.9, trend: 0.3),
        Stock(id: "WMT", name: "WildMart",            real: "Walmart",               icon: "cart.fill",                         colorHex: "#0071CE", basePrice: 23, seed: 19.3, trend: 0.5),
        Stock(id: "CSC", name: "Catsco",              real: "Costco",                icon: "basket.fill",                       colorHex: "#E31837", basePrice: 33, seed: 20.5, trend: 0.6),
        Stock(id: "TGT", name: "Tigeret",             real: "Target",                icon: "target",                            colorHex: "#CC0000", basePrice: 25, seed: 21.8, trend: -0.2),
        Stock(id: "ADC", name: "Adiclaws",            real: "Adidas",                icon: "figure.run",                        colorHex: "#20304A", basePrice: 22, seed: 22.2, trend: 0.3),
        Stock(id: "STP", name: "Starpaws",            real: "Starbucks",             icon: "cup.and.saucer.fill",               colorHex: "#00704A", basePrice: 17, seed: 23.6, trend: -0.2),
        Stock(id: "CLC", name: "ClawCola",            real: "Coca-Cola Coke",        icon: "takeoutbag.and.cup.and.straw.fill", colorHex: "#E4002B", basePrice: 14, seed: 24.1, trend: 0.2),
        Stock(id: "PWP", name: "Pawpsi",              real: "Pepsi PepsiCo",         icon: "waterbottle.fill",                  colorHex: "#004B93", basePrice: 13, seed: 25.7, trend: 0.0),
        Stock(id: "RDH", name: "RoarDash",            real: "DoorDash",              icon: "bag.fill",                          colorHex: "#FF3008", basePrice: 18, seed: 26.3, trend: 0.6),
        Stock(id: "CPT", name: "Cipawtle",            real: "Chipotle",              icon: "fork.knife",                        colorHex: "#A81612", basePrice: 29, seed: 27.9, trend: 0.4),
        Stock(id: "PRS", name: "Purrsney",            real: "Disney",                icon: "sparkles",                          colorHex: "#1E50A0", basePrice: 32, seed: 28.4, trend: 0.2),
        Stock(id: "MCT", name: "McTiger's",           real: "McDonald's",            icon: "takeoutbag.and.cup.and.straw.fill", colorHex: "#FFC72C", basePrice: 15, seed: 29.2, trend: 0.1),
        Stock(id: "NTD", name: "Nintendoar",          real: "Nintendo",              icon: "gamecontroller.fill",               colorHex: "#E60012", basePrice: 26, seed: 30.6, trend: 0.4),
        Stock(id: "APW", name: "Apawle",              real: "Apple",                 icon: "desktopcomputer",                   colorHex: "#8E8E93", basePrice: 36, seed: 31.5, trend: 0.5)
    ]

    static func stock(_ id: String) -> Stock? { stocks.first { $0.id == id } }

    /// Fixed reference point so the drift stays modest and every device agrees.
    static let epoch = Date(timeIntervalSince1970: 1_782_864_000)   // 2026-07-01

    /// Deterministic price: a real-world-ish directional drift + day/second waves.
    static func price(for stock: Stock, at date: Date) -> Double {
        let days = date.timeIntervalSince(epoch) / 86400.0
        let s = stock.seed
        let drift  = stock.trend * days * 0.006
        let waves  = sin(days * 0.55 + s) * 0.05 + sin(days * 0.21 + s * 1.4) * 0.03
        let wiggle = sin(date.timeIntervalSince1970 / 25.0 + s) * 0.012
        let factor = min(max(1 + drift + waves + wiggle, 0.3), 3.0)
        return max(1, (stock.basePrice * factor * 100).rounded() / 100)
    }

    /// `samples` evenly-spaced price points across the last `days` days.
    static func history(for stock: Stock, ending date: Date, days: Int, samples: Int) -> [PricePoint] {
        let span = Double(days) * 86400
        return (0...samples).map { i in
            let frac = Double(i) / Double(samples)
            let d = date.addingTimeInterval(-span * (1 - frac))
            return PricePoint(date: d, price: price(for: stock, at: d))
        }
    }
}

// MARK: - Portfolio

struct PortfolioRecord: Codable {
    var displayName: String
    var stripes: Double
    var shares: [String: Double]      // ticker: number of shares
    var boughtAt: [String: Date]      // ticker: when the position was opened

    init(displayName: String, stripes: Double, shares: [String: Double], boughtAt: [String: Date] = [:]) {
        self.displayName = displayName
        self.stripes = stripes
        self.shares = shares
        self.boughtAt = boughtAt
    }

    // Robust decoding: Firebase omits empty fields, so default anything missing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        displayName = (try? c.decode(String.self, forKey: .displayName)) ?? "Player"
        stripes = (try? c.decode(Double.self, forKey: .stripes)) ?? MarketConfig.startingStripes
        shares = (try? c.decode([String: Double].self, forKey: .shares)) ?? [:]
        boughtAt = (try? c.decode([String: Date].self, forKey: .boughtAt)) ?? [:]
    }
}

struct LeaderEntry: Identifiable {
    let id: String
    let name: String
    let worth: Double
    let isMe: Bool
}

// MARK: - Backend

protocol MarketBackend {
    func load(userId: String) async throws -> PortfolioRecord?
    func save(userId: String, record: PortfolioRecord) async throws
    func all() async throws -> [String: PortfolioRecord]
}

/// Single-device backend: persists the player locally and adds practice bots
/// so the leaderboard has some competition.
struct LocalBackend: MarketBackend {
    private let key = "market_localRecord"

    static let bots: [String: PortfolioRecord] = [
        "bot_whiskers": PortfolioRecord(displayName: "Whiskers 🐯", stripes: 20,
                                        shares: ["PAW": 1, "TGS": 0.5, "PVD": 0.5]),
        "bot_stripes":  PortfolioRecord(displayName: "Sir Stripes 🐅", stripes: 35,
                                        shares: ["PMZ": 1.5, "GRL": 1, "MEW": 1]),
        "bot_pounce":   PortfolioRecord(displayName: "Pounce 🐆", stripes: 10,
                                        shares: ["PAW": 0.5, "NPX": 2, "WSK": 1.5])
    ]

    func load(userId: String) async throws -> PortfolioRecord? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PortfolioRecord.self, from: data)
    }

    func save(userId: String, record: PortfolioRecord) async throws {
        UserDefaults.standard.set(try JSONEncoder().encode(record), forKey: key)
    }

    func all() async throws -> [String: PortfolioRecord] {
        var result = Self.bots
        if let mine = try await load(userId: "") {
            result["me"] = mine
        }
        return result
    }
}

/// Cross-device backend via the Firebase Realtime Database REST API.
struct FirebaseRESTBackend: MarketBackend {
    let base: String   // e.g. https://project-default-rtdb.firebaseio.com

    private func url(_ path: String) -> URL {
        URL(string: base.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + path + ".json")!
    }

    func load(userId: String) async throws -> PortfolioRecord? {
        let (data, _) = try await URLSession.shared.data(from: url("/portfolios/\(userId)"))
        if let s = String(data: data, encoding: .utf8), s == "null" || s.isEmpty { return nil }
        return try? JSONDecoder().decode(PortfolioRecord.self, from: data)
    }

    func save(userId: String, record: PortfolioRecord) async throws {
        var req = URLRequest(url: url("/portfolios/\(userId)"))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(record)
        _ = try await URLSession.shared.data(for: req)
    }

    func all() async throws -> [String: PortfolioRecord] {
        let (data, _) = try await URLSession.shared.data(from: url("/portfolios"))
        return (try? JSONDecoder().decode([String: PortfolioRecord].self, from: data)) ?? [:]
    }
}

// MARK: - Store

@MainActor
final class MarketStore: ObservableObject {

    @Published var record: PortfolioRecord
    @Published var leaderboard: [LeaderEntry] = []
    @Published var popularity: [String: Double] = [:]   // ticker -> total shares held by all players
    @Published private(set) var now = Date()

    let userId: String
    private let backend: MarketBackend
    private var ticks = 0
    private var loop: Task<Void, Never>?

    // Local mirror key: always saved on every buy/sell so data survives network outages.
    private let mirrorKey = "market_localMirror"

    init() {
        // Stable per-install id.
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: "market_userId") {
            userId = existing
        } else {
            let new = UUID().uuidString
            defaults.set(new, forKey: "market_userId")
            userId = new
        }

        let username = defaults.string(forKey: "market_username")
        let display = (username?.isEmpty == false) ? username! : "Player"

        // Start with local mirror so the UI is populated immediately — no async flash.
        if let data = defaults.data(forKey: "market_localMirror"),
           let cached = try? JSONDecoder().decode(PortfolioRecord.self, from: data) {
            record = cached
        } else {
            record = PortfolioRecord(displayName: display,
                                     stripes: MarketConfig.startingStripes,
                                     shares: [:])
        }

        backend = MarketConfig.backendURL.map { FirebaseRESTBackend(base: $0) } ?? LocalBackend()
    }

    // MARK: Prices & value

    func price(_ stock: Stock) -> Double { Market.price(for: stock, at: now) }

    /// Price 5 minutes ago, for a simple up/down change indicator.
    func priceEarlier(_ stock: Stock) -> Double {
        Market.price(for: stock, at: now.addingTimeInterval(-300))
    }

    func shares(_ stock: Stock) -> Double { record.shares[stock.id] ?? 0 }

    func changePct(_ stock: Stock) -> Double {
        let earlier = priceEarlier(stock)
        return earlier > 0 ? (price(stock) - earlier) / earlier : 0
    }

    /// Top 5 by how many shares players hold; ties fall back to real-world trend.
    var trendingStocks: [Stock] {
        Market.stocks.sorted { a, b in
            let pa = popularity[a.id] ?? 0
            let pb = popularity[b.id] ?? 0
            if pa != pb { return pa > pb }
            return a.trend > b.trend
        }
        .prefix(5)
        .map { $0 }
    }

    var holdingsValue: Double {
        Market.stocks.reduce(0) { $0 + (record.shares[$1.id] ?? 0) * price($1) }
    }

    var netWorth: Double { record.stripes + holdingsValue }

    private func netWorth(of rec: PortfolioRecord) -> Double {
        rec.stripes + Market.stocks.reduce(0) { $0 + (rec.shares[$1.id] ?? 0) * Market.price(for: $1, at: now) }
    }

    // MARK: Trading

    func maxAffordable(_ stock: Stock) -> Int {
        Int((record.stripes / price(stock)).rounded(.down))
    }

    func buy(_ stock: Stock, shares count: Double) {
        let cost = count * price(stock)
        guard count > 0, record.stripes >= cost else { return }
        if (record.shares[stock.id] ?? 0) <= 0 {
            record.boughtAt[stock.id] = now   // start the 1-day hold clock
        }
        record.stripes -= cost
        record.shares[stock.id, default: 0] += count
        persist()
    }

    /// A stock can only be sold once it's been held for at least a day.
    func canSell(_ stock: Stock) -> Bool {
        guard shares(stock) > 0 else { return false }
        guard let bought = record.boughtAt[stock.id] else { return true }
        return now.timeIntervalSince(bought) >= 86400
    }

    func secondsUntilSellable(_ stock: Stock) -> TimeInterval {
        guard let bought = record.boughtAt[stock.id] else { return 0 }
        return max(0, 86400 - now.timeIntervalSince(bought))
    }

    func sell(_ stock: Stock, shares count: Double) {
        guard canSell(stock) else { return }
        let owned = shares(stock)
        let n = min(count, owned)
        guard n > 0 else { return }
        record.stripes += n * price(stock)
        let remaining = owned - n
        if remaining <= 0.0001 {
            record.shares[stock.id] = nil
            record.boughtAt[stock.id] = nil
        } else {
            record.shares[stock.id] = remaining
        }
        persist()
    }

    // MARK: Lifecycle

    func start() {
        guard loop == nil else { return }
        Task { await load() }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard let self else { return }
                await MainActor.run { self.now = Date() }
                self.ticks += 1
                if self.ticks % 4 == 0 { await self.refreshLeaderboard() }   // ~every 8s
            }
        }
    }

    func stop() { loop?.cancel(); loop = nil }

    private func persist() {
        let snapshot = record
        // Always mirror locally so data survives network outages and app restarts.
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: mirrorKey)
        }
        Task { try? await backend.save(userId: userId, record: snapshot) }
    }

    private func load() async {
        if let saved = try? await backend.load(userId: userId) {
            record = saved
            // Mirror the freshly-loaded remote data locally.
            if let data = try? JSONEncoder().encode(saved) {
                UserDefaults.standard.set(data, forKey: mirrorKey)
            }
        } else if let data = UserDefaults.standard.data(forKey: mirrorKey),
                  let cached = try? JSONDecoder().decode(PortfolioRecord.self, from: data) {
            // Network unavailable — fall back to the local mirror, don't overwrite with defaults.
            record = cached
        } else {
            persist()   // first run: register this player with default values
        }
        // Add any stripes earned from completing banking lessons.
        let earned = StripeBank.claimPending()
        if earned != 0 {
            record.stripes += earned
            persist()
        }
        await refreshLeaderboard()
    }

    // MARK: Username

    /// True if another player has already claimed this name.
    func usernameTaken(_ name: String) async -> Bool {
        let all = (try? await backend.all()) ?? [:]
        let lower = name.lowercased()
        return all.contains { key, rec in
            key != userId && rec.displayName.lowercased() == lower
        }
    }

    func setUsername(_ name: String) {
        record.displayName = name
        persist()
    }

    func refreshLeaderboard() async {
        let all = (try? await backend.all()) ?? [:]

        // Popularity = total shares held across everyone.
        var pop: [String: Double] = [:]
        for (_, rec) in all {
            for (ticker, count) in rec.shares where count > 0 { pop[ticker, default: 0] += count }
        }
        if all[userId] == nil {
            for (ticker, count) in record.shares where count > 0 { pop[ticker, default: 0] += count }
        }
        popularity = pop

        var entries: [LeaderEntry] = all.map { key, rec in
            LeaderEntry(id: key, name: rec.displayName, worth: netWorth(of: rec), isMe: key == userId)
        }
        if !entries.contains(where: { $0.isMe }) {
            entries.append(LeaderEntry(id: userId, name: record.displayName, worth: netWorth, isMe: true))
        }
        leaderboard = entries.sorted { $0.worth > $1.worth }
    }
}
