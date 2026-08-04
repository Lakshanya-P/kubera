import SwiftUI

// MARK: - Main View

struct BankingBasicsView: View {

    @State private var selection = 0

    // Bitmask tracking whether each lesson has been completed at ANY difficulty.
    @AppStorage("bankDoneMask") private var doneMask = 0

    private let lessons: [(title: String, lesson: LessonType, color: Color, icon: String)] = [
        ("Banking Basics",         .lesson1, Theme.primary,   "building.columns.fill"),
        ("Saving & Goals",         .lesson2, Theme.secondary, "target"),
        ("Budgeting & Debit Cards",.lesson3, Theme.purple,    "creditcard.fill"),
        ("Advanced Banking",       .lesson4, Theme.coral,     "chart.line.uptrend.xyaxis")
    ]

    private func isDone(_ number: Int) -> Bool { doneMask & (1 << (number - 1)) != 0 }

    /// True when the current AgeBand is higher than the band at which the lesson was last completed.
    private func canEarnStripes(_ lesson: LessonType) -> Bool {
        let stored = UserDefaults.standard.integer(forKey: lesson.maxBandKey)
        return AgeBand.current.bandLevel > stored
    }

    var body: some View {
        ZStack {
            AppBackground(image: "background4")

            GeometryReader { geo in
                VStack(spacing: Theme.Space.m) {

                    Text("Banking Lessons")
                        .font(.title.weight(.heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)

                    TabView(selection: $selection) {
                        ForEach(lessons.indices, id: \.self) { i in
                            lessonSlide(lessons[i])
                                .padding(.horizontal, Theme.Space.xs)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: max(geo.size.height * 0.30, 220))
                    .tutorialAnchor("banking.lessons")

                    Text("Swipe to see all four lessons")
                        .font(.footnote)
                        .foregroundStyle(Theme.ink.opacity(0.5))
                }
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .padding()
                .frame(minHeight: geo.size.height)
            }
        }
        .navigationTitle("Banking")
        .inlineNavigationTitle()
        .coachMarks(.banking)
    }

    private func lessonSlide(_ item: (title: String, lesson: LessonType, color: Color, icon: String)) -> some View {
        let number = item.lesson.number
        let done = isDone(number)
        let canEarn = canEarnStripes(item.lesson)
        // Label and accent colour signal whether new stripes are available.
        let buttonLabel = !done ? "Start Lesson 🚀" : (canEarn ? "New Level! 🔥" : "Review Lesson")
        let badgeColor: Color = canEarn && done ? Theme.accent : item.color

        return VStack(spacing: Theme.Space.s) {
            HStack(spacing: Theme.Space.s) {
                ZStack {
                    Circle().fill(.white.opacity(0.25)).frame(width: 48, height: 48)
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lesson \(number)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(item.title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                if done {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }

            if canEarn && done {
                Text("Higher difficulty unlocked! 🌟")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            NavigationLink {
                LessonView(lesson: item.lesson)
            } label: {
                Text(buttonLabel)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(badgeColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Space.m)
        .padding(.bottom, Theme.Space.m)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.color, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .shadow(color: item.color.opacity(0.35), radius: 10, y: 6)
    }
}

// MARK: - Lesson Types

enum LessonType {
    case lesson1, lesson2, lesson3, lesson4

    var number: Int {
        switch self { case .lesson1: 1; case .lesson2: 2; case .lesson3: 3; case .lesson4: 4 }
    }

    /// Key storing the highest AgeBand.bandLevel at which this lesson was completed.
    var maxBandKey: String { "bankL\(number)MaxBand" }

    /// Age-appropriate slides; always calls AgeBand.current at the moment the lesson opens.
    var slides: [Slide] { slides(for: AgeBand.current) }

    func slides(for band: AgeBand) -> [Slide] {
        switch self {
        case .lesson1: return LessonContent.lesson1(band)
        case .lesson2: return LessonContent.lesson2(band)
        case .lesson3: return LessonContent.lesson3(band)
        case .lesson4: return LessonContent.lesson4(band)
        }
    }
}

// MARK: - Lesson View

struct LessonView: View {

    let lesson: LessonType

    @State private var currentIndex = 0
    @State private var currentGameSolved = false
    @Environment(\.dismiss) private var dismiss

    @AppStorage("bankDoneMask") private var doneMask = 0
    @AppStorage("bankLastCompleted") private var lastCompleted = 0

    @StateObject private var speech = SpeechManager()
    @State private var earnedReward = 0
    @State private var showReward = false

    private var lessonSlides: [Slide] { lesson.slides }
    private var currentSlide: Slide { lessonSlides[currentIndex] }
    private var isLastSlide: Bool { currentIndex >= lessonSlides.count - 1 }
    private var narration: String { "\(currentSlide.title). \(currentSlide.content)" }

    /// Next button is locked while the current slide has an unsolved game.
    private var nextBlocked: Bool { currentSlide.game != nil && !currentGameSolved }

    var body: some View {
        ZStack {
            AppBackground(image: "background4")

            VStack(spacing: Theme.Space.m) {

                HStack(spacing: Theme.Space.s) {
                    ProgressView(value: Double(currentIndex + 1), total: Double(lessonSlides.count))
                        .tint(Theme.primary)
                    Button {
                        if speech.isSpeaking { speech.pause() }
                        else if speech.isPaused { speech.resume() }
                        else { speech.speak(narration) }
                    } label: {
                        Image(systemName: speech.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.primary)
                    }
                    .accessibilityLabel(speech.isSpeaking ? "Pause narration" : "Play narration")
                }

                SlideView(slide: currentSlide, onGameSolved: {
                    withAnimation { currentGameSolved = true }
                })
                .id(currentIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))

                VStack(spacing: 6) {
                    Button {
                        if isLastSlide { completeLesson() }
                        else { withAnimation(.easeInOut) { currentIndex += 1 } }
                    } label: {
                        Text(isLastSlide ? "Finish 🎉" : "Next")
                            .font(.title2.weight(.bold))
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: isLastSlide ? Theme.secondary : Theme.primary))
                    .disabled(nextBlocked)
                    .opacity(nextBlocked ? 0.4 : 1)

                    if nextBlocked {
                        Text("Answer the question above to continue! 👆")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                    }
                }
            }
            .responsiveWidth()
            .padding()
        }
        .navigationTitle("Lesson \(lesson.number)")
        .inlineNavigationTitle()
        .keyboardDoneButton()
        .onAppear { speech.speak(narration) }
        .onChange(of: currentIndex) { _, _ in
            currentGameSolved = false
            speech.speak(narration)
        }
        .onDisappear { speech.stop() }
        .alert("Lesson complete! 🎉", isPresented: $showReward) {
            Button("Awesome!") { dismiss() }
        } message: {
            Text("You earned \(earnedReward) stripe\(earnedReward == 1 ? "" : "s") to invest in the Tiger Market! 🐯\n\nKeep completing lessons at higher difficulty levels to earn more!")
        }
    }

    private func completeLesson() {
        speech.stop()
        let currentBandLevel = AgeBand.current.bandLevel
        let maxBand = UserDefaults.standard.integer(forKey: lesson.maxBandKey)

        // Always mark as done for the badge.
        doneMask |= (1 << (lesson.number - 1))
        lastCompleted = lesson.number

        if currentBandLevel > maxBand {
            // New or higher difficulty: award exactly 1 stripe.
            UserDefaults.standard.set(currentBandLevel, forKey: lesson.maxBandKey)
            StripeBank.grant(1)
            earnedReward = 1
            showReward = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Lesson Content

struct LessonContent {

    // MARK: - Shared intro slide (Lesson 1 only)

    private static let stripesIntro = Slide(
        title: "🐯 Introducing Stripes!",
        content: "Here is your very own tiger currency!\n\nStripes are special game points you earn by completing lessons. They are NOT real money — they belong only to YOU in this app!\n\nInvest your stripes in the Tiger Market to grow them and compete with friends.\n\nEarn more stripes by finishing all four lessons! 🌟",
        imageName: nil, game: nil, emoji: "🐯"
    )

    // MARK: - Lesson 1: Banking Basics

    static func lesson1(_ band: AgeBand) -> [Slide] {
        switch band {
        case .young:  return [stripesIntro] + lesson1Young
        case .mid:    return [stripesIntro] + lesson1Mid
        case .older:  return [stripesIntro] + lesson1Older
        }
    }

    private static let lesson1Young: [Slide] = [
        Slide(title: "🏦 What is a Bank?",
              content: "A bank is like a super-safe piggy bank! It keeps your money locked up tight and protected. When you want your money back, it's always there! 🔒",
              imageName: nil, game: nil, emoji: "🏦"),
        Slide(title: "💰 Your Account",
              content: "An account is YOUR special space at the bank — like your own magic drawer where your money lives safely!\n\nThe bank keeps track of every cent for you.",
              imageName: nil,
              game: .multipleChoice(question: "What does a bank account do?",
                                    options: ["Spend your money for you", "Keep your money safe", "Give toys to kids"],
                                    correctIndex: 1),
              emoji: "💰"),
        Slide(title: "⬆️ Deposit = Money IN!",
              content: "When you PUT money into the bank, it's called a DEPOSIT.\n\nYou deposit your birthday money to keep it safe! ⬆️",
              imageName: nil,
              game: .multipleChoice(question: "You put $10 in the bank. That's called a...",
                                    options: ["Withdrawal", "Deposit", "Trade"],
                                    correctIndex: 1),
              emoji: "⬆️"),
        Slide(title: "⬇️ Withdraw = Money OUT!",
              content: "When you TAKE money out of the bank, it's called a WITHDRAWAL.\n\nYou withdraw money when you want to buy something! ⬇️",
              imageName: nil,
              game: .multipleChoice(question: "Taking money OUT of the bank is called...",
                                    options: ["Depositing", "Saving", "Withdrawing"],
                                    correctIndex: 2),
              emoji: "⬇️"),
        Slide(title: "🌟 Banking Star!",
              content: "Amazing work! You now know:\n\n🏦 Bank = super-safe place for money\n💰 Account = YOUR money space\n⬆️ Deposit = money IN\n⬇️ Withdraw = money OUT\n\nUse your tiger stripes to invest in the Tiger Market! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson1Mid: [Slide] = [
        Slide(title: "🏦 What is a Bank?",
              content: "Banks are trusted businesses that keep your money safe. They're insured by the government (FDIC), so your money is protected even if the bank has problems!\n\nBanks also pay YOU a little extra — called INTEREST — just for keeping your money there.",
              imageName: nil,
              game: .multipleChoice(question: "Why is a bank safer than keeping cash at home?",
                                    options: ["It earns interest automatically", "It's FDIC insured by the government", "Both of these!"],
                                    correctIndex: 2),
              emoji: "🏦"),
        Slide(title: "💳 Checking Account",
              content: "A CHECKING account is for everyday spending — groceries, bills, buying things online.\n\n💡 Key terms:\n• BALANCE = how much money you have right now\n• DEBIT CARD = spends directly from this account",
              imageName: nil,
              game: .multipleChoice(question: "Which account is designed for everyday spending?",
                                    options: ["Savings Account", "Checking Account", "Investment Account"],
                                    correctIndex: 1),
              emoji: "💳"),
        Slide(title: "🐷 Savings Account",
              content: "A SAVINGS account is for money you're keeping for later. Banks pay you INTEREST — a little extra — just for leaving your money there!\n\n💡 Example: Save $100 at 5% interest = you earn $5 extra per year! Free money! 💰",
              imageName: nil,
              game: .math(question: "You save $200 at 5% interest. How much do you earn? (200 × 0.05)", answer: 10),
              emoji: "🐷"),
        Slide(title: "🔄 Deposits & Withdrawals",
              content: "DEPOSIT = money coming IN to your account ⬆️\nWITHDRAWAL = money going OUT ⬇️\n\nAlways check your BALANCE after each transaction to know exactly how much you have!",
              imageName: nil,
              game: .math(question: "Start with $50. Deposit $30. Withdraw $20. What's your balance?", answer: 60),
              emoji: "🔄"),
        Slide(title: "🏧 ATM & Debit Cards",
              content: "An ATM (Automated Teller Machine) lets you take out cash any time, day or night.\n\nYour DEBIT CARD spends money directly from your checking account — just like cash but more convenient!\n\n🔐 NEVER share your PIN (Personal Identification Number) with anyone!",
              imageName: nil,
              game: .multipleChoice(question: "What does a debit card spend?",
                                    options: ["Borrowed money", "Money from your account", "Tiger stripes"],
                                    correctIndex: 1),
              emoji: "🏧"),
        Slide(title: "🔐 Stay Safe!",
              content: "✅ Use a strong, unique password\n✅ NEVER share your PIN or password — not even with friends\n✅ Log out of banking apps when done\n✅ Check your statements for mistakes\n❌ Never use public WiFi for banking",
              imageName: nil, game: nil, emoji: "🔐"),
        Slide(title: "🌟 Banking Pro!",
              content: "You learned so much!\n\n🏦 Banks: safe & FDIC insured\n💳 Checking = spending money\n🐷 Savings = growing money\n🔄 Deposit in, Withdraw out\n🏧 Debit card = real money\n\nNow earn more stripes and invest in the Tiger Market! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson1Older: [Slide] = [
        Slide(title: "🏦 Banks vs Credit Unions",
              content: "BANKS are for-profit companies owned by shareholders.\nCREDIT UNIONS are non-profits owned by their members — YOU!\n\nCredit unions often have lower fees and better interest rates. Both are FDIC/NCUA insured up to $250,000 per account.",
              imageName: nil,
              game: .multipleChoice(question: "Which institution is typically member-owned and non-profit?",
                                    options: ["A commercial bank", "A credit union", "A hedge fund"],
                                    correctIndex: 1),
              emoji: "🏦"),
        Slide(title: "📋 Account Types",
              content: "CHECKING – Daily spending, easy access, little/no interest\nSAVINGS – Higher interest, good for short-term goals\nMONEY MARKET – Higher interest, larger minimum balance required\nCDs (Certificates of Deposit) – Fixed interest rate, locked for 1 month–5 years\n\n📌 More restrictions usually means more interest earned.",
              imageName: nil,
              game: .multipleChoice(question: "Which account locks your money for a fixed term for higher interest?",
                                    options: ["Checking", "Savings", "Certificate of Deposit"],
                                    correctIndex: 2),
              emoji: "📋"),
        Slide(title: "💹 How Banks Make Money",
              content: "Banks take YOUR deposits and lend them to borrowers (mortgages, car loans, businesses) at HIGHER interest rates.\n\nExample:\n• They pay you 4% on savings\n• They charge borrowers 7% on loans\n• The 3% difference is their profit — called the INTEREST RATE SPREAD.",
              imageName: nil,
              game: .math(question: "Bank pays 3% on savings, charges 8% on loans. What's the spread (in %)?", answer: 5),
              emoji: "💹"),
        Slide(title: "🛡️ FDIC Insurance",
              content: "The FDIC (Federal Deposit Insurance Corporation) guarantees your deposits up to $250,000 per bank, per account category.\n\nIf your bank fails, the US government pays you back — up to the limit.\n\nCredit unions use NCUA for identical protection.",
              imageName: nil,
              game: .math(question: "You have $300,000 at one bank. FDIC covers $250,000. How much (in $) is unprotected?", answer: 50000),
              emoji: "🛡️"),
        Slide(title: "📊 APY & Interest Rates",
              content: "APY = Annual Percentage Yield — the real return including compounding.\n\nFormula: Interest = Principal × APY\n\n💡 Example: $2,000 at 4% APY earns $80 per year.\n\nAlways compare APYs when choosing a savings account — small differences add up over time!",
              imageName: nil,
              game: .math(question: "You have $1,000 in a 6% APY account. How much interest do you earn in one year?", answer: 60),
              emoji: "📊"),
        Slide(title: "🔢 Routing & Account Numbers",
              content: "Every bank account has two key numbers:\n\nROUTING NUMBER – 9 digits identifying your specific bank (like a postal code for money transfers)\nACCOUNT NUMBER – Your personal account at that bank\n\nBoth are needed for direct deposit, wire transfers, and paying bills electronically.",
              imageName: nil,
              game: .multipleChoice(question: "Which number uniquely identifies YOUR specific account?",
                                    options: ["Routing number", "Account number", "SSN"],
                                    correctIndex: 1),
              emoji: "🔢"),
        Slide(title: "🔐 Cybersecurity",
              content: "🎣 PHISHING – Fake emails or texts pretending to be your bank to steal info\n🔑 2FA – Two-Factor Authentication: password PLUS a code sent to your phone\n🔒 Use unique 12+ character passwords for every account\n🚨 Never click links in unexpected banking emails\n✅ Always go directly to your bank's official website",
              imageName: nil,
              game: .multipleChoice(question: "A stranger emails 'Your account is locked, click here to fix it.' What should you do?",
                                    options: ["Click the link quickly", "Call your bank's official number directly", "Reply with your account info"],
                                    correctIndex: 1),
              emoji: "🔐"),
        Slide(title: "🏆 Banking Master!",
              content: "You've mastered real-world banking:\n\n🏦 Banks vs Credit Unions\n📋 Checking, Savings, CD accounts\n🛡️ FDIC protects up to $250K\n📊 APY = your real interest rate\n🔢 Routing & Account numbers\n🔐 Cyber safety basics\n\nNow invest your tiger stripes and dominate the Tiger Market! 🐯",
              imageName: nil, game: nil, emoji: "🏆")
    ]

    // MARK: - Lesson 2: Saving & Goals

    static func lesson2(_ band: AgeBand) -> [Slide] {
        switch band {
        case .young:  return lesson2Young
        case .mid:    return lesson2Mid
        case .older:  return lesson2Older
        }
    }

    private static let lesson2Young: [Slide] = [
        Slide(title: "🐷 Why Save?",
              content: "Saving means keeping some money for LATER instead of spending it all now!\n\nIf you want a big toy that costs $20, you need to save $20 first.\n\nSaving = future fun! 🎉",
              imageName: nil, game: nil, emoji: "🐷"),
        Slide(title: "🤔 Needs vs Wants",
              content: "NEEDS = things you MUST have to live safely (food, home, clothes, medicine)\nWANTS = fun things that make life exciting (toys, games, candy)\n\nNeeds come first! Always. 🍎",
              imageName: nil, game: .needsVsWants, emoji: "🤔"),
        Slide(title: "🎯 Set a Goal!",
              content: "Pick something you want to save for. Count how long it will take — and keep going!\n\nEvery dollar saved gets you closer to your goal. 🎯",
              imageName: nil,
              game: .math(question: "A toy costs $40. You save $10 each week. How many weeks to save enough?", answer: 4),
              emoji: "🎯"),
        Slide(title: "✨ Interest = Bonus Money!",
              content: "When you save money at a bank, they give you a little EXTRA called INTEREST!\n\nExample: Save $100, bank gives you $5 extra. Now you have $105! 🎁\n\nThe longer you save, the more bonus money you get!",
              imageName: nil, game: nil, emoji: "✨"),
        Slide(title: "🌟 Super Saver!",
              content: "Incredible! You learned:\n\n🐷 Save some of every dollar you get\n🍎 Always cover needs before wants\n🎯 Pick goals and save toward them\n✨ Banks pay bonus interest\n\nKeep earning tiger stripes to invest! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson2Mid: [Slide] = [
        Slide(title: "🐷 Pay Yourself First",
              content: "The #1 savings trick: every time you get money, SAVE SOME FIRST — before you spend anything!\n\nExample: Get $20 allowance → Save $5 first → Spend $15.\n\nDo this every time, and your savings will grow fast! 🚀",
              imageName: nil,
              game: .multipleChoice(question: "What does 'Pay Yourself First' mean?",
                                    options: ["Buy what you want first", "Save before you spend anything", "Spend everything you earn"],
                                    correctIndex: 1),
              emoji: "🐷"),
        Slide(title: "🤔 Needs vs Wants",
              content: "NEEDS = food, shelter, clothing, school supplies, medicine\nWANTS = video games, snacks, new shoes you don't need, streaming services\n\nSmart spenders always cover NEEDS first, then enjoy WANTS with what's left!",
              imageName: nil, game: .needsVsWants, emoji: "🤔"),
        Slide(title: "⛑️ Emergency Fund",
              content: "An EMERGENCY FUND is money set aside for unexpected surprises — a broken phone, medical visit, unexpected bill.\n\n💡 Goal: save enough to cover at least 1–2 months of expenses.\n\nWhen emergencies happen, you won't panic! 💪",
              imageName: nil,
              game: .multipleChoice(question: "What is an emergency fund used for?",
                                    options: ["Vacation spending", "Unexpected expenses", "Daily groceries"],
                                    correctIndex: 1),
              emoji: "⛑️"),
        Slide(title: "🎯 SMART Goals",
              content: "The best goals are SMART:\n✅ Specific — what exactly?\n✅ Measurable — how much?\n✅ Achievable — can you do it?\n✅ Relevant — does it matter?\n✅ Time-bound — by when?\n\n❌ 'Save money' is vague.\n✅ 'Save $120 in 3 months' is SMART!",
              imageName: nil,
              game: .math(question: "Goal: save $120 in 3 months. How much do you need to save per month?", answer: 40),
              emoji: "🎯"),
        Slide(title: "✨ Interest = Free Money",
              content: "SIMPLE INTEREST formula:\nInterest = Principal × Rate\n\n📖 Example: $300 at 5% interest per year = $300 × 0.05 = $15 earned in one year!\n\nThat's $15 just for saving. Banks pay YOU to keep your money there! 💰",
              imageName: nil,
              game: .math(question: "You save $400 at 5% interest. How much interest do you earn in one year?", answer: 20),
              emoji: "✨"),
        Slide(title: "🌟 Saving Champion!",
              content: "Look at what you've learned!\n\n🐷 Pay yourself first every time\n⛑️ Build an emergency fund\n🎯 Set SMART goals\n✨ Interest = free money from banks\n\nInvest your tiger stripes wisely in the Tiger Market! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson2Older: [Slide] = [
        Slide(title: "🐷 Automate Your Savings",
              content: "The best savers automate it! Set up an AUTO-TRANSFER from checking to savings every payday — before you have a chance to spend it.\n\n📊 Research shows people who automate savings save 3× more than those who don't.\n\nOut of sight = out of mind = more saved! 🚀",
              imageName: nil,
              game: .multipleChoice(question: "Why is automatic savings more effective than manual savings?",
                                    options: ["It earns higher interest", "You can't forget or skip it", "Banks require it"],
                                    correctIndex: 1),
              emoji: "🐷"),
        Slide(title: "🤔 Needs vs Wants (Advanced)",
              content: "In real life, the line between needs and wants gets tricky!\n\nIs a gym membership a need? Depends on your health.\nIs a phone a need? Often yes for work and safety.\nIs organic food a need? Base food is, organic might be a want.\n\nThe key: be HONEST with yourself.",
              imageName: nil, game: .needsVsWants, emoji: "🤔"),
        Slide(title: "⛑️ The 3–6 Month Rule",
              content: "Financial experts recommend saving 3–6 months of living expenses as your emergency fund.\n\n📌 Example: Monthly expenses = $2,000\n→ Emergency fund goal = $6,000–$12,000\n\nKeep it in a HIGH-YIELD savings account so it earns interest while it waits for emergencies!",
              imageName: nil,
              game: .math(question: "Monthly expenses: $1,500. Goal: 4 months of expenses. What's your target ($)?", answer: 6000),
              emoji: "⛑️"),
        Slide(title: "📈 Compound Interest",
              content: "COMPOUND interest earns interest ON your previous interest — a snowball rolling downhill!\n\n🔢 Rule of 72: Divide 72 by your annual interest rate to find how many years to DOUBLE your money.\n\nExample: 6% interest → 72 ÷ 6 = 12 years to double!\nExample: 9% interest → 72 ÷ 9 = 8 years to double! 🚀",
              imageName: nil,
              game: .math(question: "Interest rate: 8%. Using Rule of 72, in how many years does your money double?", answer: 9),
              emoji: "📈"),
        Slide(title: "🏦 High-Yield Savings",
              content: "Traditional bank savings: ~0.4% APY\nHigh-Yield Savings Accounts (HYSA): 4–5% APY\n\nHYSAs are online savings accounts with much better rates — and they're equally FDIC insured and just as safe!\n\n💡 Moving $10,000 from 0.5% to 5% = $450 MORE per year. That adds up fast!",
              imageName: nil,
              game: .math(question: "$5,000 in a 4% APY high-yield account. How much interest do you earn in one year?", answer: 200),
              emoji: "🏦"),
        Slide(title: "📊 50/30/20 Budget Rule",
              content: "A classic budgeting framework:\n\n50% → Needs (rent, food, utilities, insurance)\n30% → Wants (dining out, subscriptions, fun)\n20% → Savings & paying down debt\n\nAdjust these ratios based on your personal goals. Some people do 70/20/10 or 60/20/20.",
              imageName: nil,
              game: .math(question: "Monthly income: $1,000. Applying 20% savings rule. How much ($) do you save?", answer: 200),
              emoji: "📊"),
        Slide(title: "🌟 Financial Genius!",
              content: "You've mastered savings strategy:\n\n🤖 Automate savings — set it and forget it!\n⛑️ 3–6 month emergency fund\n📈 Compound interest doubles money over time\n🏦 High-yield accounts earn more\n📊 50/30/20 framework for budgeting\n\nNow put your stripes to work in the Tiger Market! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    // MARK: - Lesson 3: Budgeting & Debit Cards

    static func lesson3(_ band: AgeBand) -> [Slide] {
        switch band {
        case .young:  return lesson3Young
        case .mid:    return lesson3Mid
        case .older:  return lesson3Older
        }
    }

    private static let lesson3Young: [Slide] = [
        Slide(title: "📋 What's a Budget?",
              content: "A BUDGET is a plan for your money! It tells each dollar exactly where to go before you spend it.\n\nThink of it like a treasure map for your money — you decide where it all goes! 🗺️",
              imageName: nil, game: nil, emoji: "📋"),
        Slide(title: "💳 Your Debit Card",
              content: "A DEBIT CARD spends the REAL money in your bank account — just like using cash, but it's a card!\n\n⚠️ Important: If you spend more than you have, you get an OVERDRAFT — and that costs extra fees!",
              imageName: nil,
              game: .multipleChoice(question: "A debit card takes money from...",
                                    options: ["A credit line", "Your bank account", "Tiger stripes"],
                                    correctIndex: 1),
              emoji: "💳"),
        Slide(title: "🛒 Spend Wisely",
              content: "Before buying something, ask yourself:\n1️⃣ Do I really need this?\n2️⃣ Do I have enough money?\n3️⃣ Is there a cheaper option?\n\nSmart shoppers compare prices and check their balance first! 🔍",
              imageName: nil,
              game: .math(question: "You have $20. You buy a snack for $3 and a book for $8. How much is left?", answer: 9),
              emoji: "🛒"),
        Slide(title: "🐯 Tiger Stripes Market!",
              content: "Great news! In the Tiger Market, you invest STRIPES — your special tiger currency!\n\nNo real money is at risk — it's safe practice! But the skills you learn here are REAL investing skills.\n\nBuy low, sell high! 📈",
              imageName: nil, game: nil, emoji: "🐯"),
        Slide(title: "🌟 Budget Boss!",
              content: "Excellent work! You know:\n\n📋 Budget = a plan for your money\n💳 Debit card = real money from your account\n🛒 Check balance before spending\n🐯 Tiger stripes = safe investing practice\n\nKeep earning stripes and learning! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson3Mid: [Slide] = [
        Slide(title: "📋 Make a Budget",
              content: "A healthy budget has 3 parts:\n\n💚 NEEDS – food, clothing, school supplies, shelter\n💛 WANTS – games, snacks, fun extras\n💙 SAVINGS – for goals and emergencies\n\nA classic split: 50% needs · 30% wants · 20% savings",
              imageName: nil,
              game: .multipleChoice(question: "A complete budget includes...",
                                    options: ["Only needs", "Only wants", "Needs + Wants + Savings"],
                                    correctIndex: 2),
              emoji: "📋"),
        Slide(title: "💳 Debit vs Credit",
              content: "DEBIT CARD – Spends YOUR money from your bank account right now. Limit = what you have.\n\nCREDIT CARD – Borrows money from the bank to pay back later. Limit = your credit limit.\n\n⚠️ Paying credit late = interest charges + hurt credit score!",
              imageName: nil,
              game: .multipleChoice(question: "Which card only lets you spend money you already have?",
                                    options: ["Credit card", "Debit card", "Gift card"],
                                    correctIndex: 1),
              emoji: "💳"),
        Slide(title: "🛒 Track Your Spending",
              content: "Write down or use an app to log every purchase. When you SEE where your money goes, you can make smarter choices!\n\n💡 Categories to track: food, entertainment, clothing, transport, savings",
              imageName: nil,
              game: .math(question: "You spend: $15 on food, $10 on fun, $5 on transport. Total spent ($)?", answer: 30),
              emoji: "🛒"),
        Slide(title: "⚠️ Avoid Overdrafts!",
              content: "An OVERDRAFT happens when you spend MORE money than you have in your account.\n\nBanks charge OVERDRAFT FEES — often $25–$35 per transaction!\n\n✅ Set up low-balance alerts on your banking app\n✅ Always check your balance before big purchases",
              imageName: nil,
              game: .multipleChoice(question: "What is an overdraft?",
                                    options: ["Earning bonus interest", "Spending more money than you have", "A type of savings account"],
                                    correctIndex: 1),
              emoji: "⚠️"),
        Slide(title: "🐯 Tiger Market Practice",
              content: "The Tiger Market lets you practice REAL investing skills with tiger stripes — no real money at risk!\n\n💡 You'll practice the same skills used with real stocks:\n• Buying low, selling high\n• Spreading across different companies\n• Watching price trends 📈",
              imageName: nil, game: nil, emoji: "🐯"),
        Slide(title: "🌟 Budget Pro!",
              content: "You're a budgeting champion!\n\n📋 Budget = Needs + Wants + Savings\n💳 Debit = your real money\n🛒 Track spending to stay on budget\n⚠️ Avoid costly overdraft fees\n🐯 Tiger Market = real skills, no real risk\n\nKeep growing! 🐯",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson3Older: [Slide] = [
        Slide(title: "📋 Zero-Based Budgeting",
              content: "In ZERO-BASED BUDGETING, every dollar gets an assigned job — income minus all assignments = $0.\n\nThis doesn't mean spending everything! Savings and investing are assignments too.\n\nIncome: $2,000\nNeeds: $1,000 · Wants: $400 · Savings: $400 · Investing: $200 = $0 ✅",
              imageName: nil,
              game: .math(question: "Income: $1,500. Needs: $700, Wants: $400, Savings: $300. Assign rest to investing ($):", answer: 100),
              emoji: "📋"),
        Slide(title: "💳 Credit Cards: The Full Picture",
              content: "Key credit card terms:\n\nAPR – Annual Percentage Rate (interest charged if you carry a balance)\nGrace Period – ~21-25 days to pay with ZERO interest\nMinimum Payment – Tiny amount that keeps your balance growing\n\n💡 Always pay the FULL balance! Minimum payment + 22% APR = debt trap that grows every month!",
              imageName: nil,
              game: .multipleChoice(question: "To avoid credit card interest charges, you should...",
                                    options: ["Pay only the minimum", "Pay the full balance each month", "Never use it at all"],
                                    correctIndex: 1),
              emoji: "💳"),
        Slide(title: "📊 Fixed vs Variable Expenses",
              content: "FIXED EXPENSES – Same amount every month:\n• Rent, loan payments, insurance, subscriptions\n\nVARIABLE EXPENSES – Change each month:\n• Groceries, gas, dining out, clothing\n\n💡 Fixed expenses are easier to plan for. Variable ones need a spending limit each month.",
              imageName: nil,
              game: .multipleChoice(question: "Which is an example of a variable expense?",
                                    options: ["Monthly rent", "Your grocery bill", "Car insurance payment"],
                                    correctIndex: 1),
              emoji: "📊"),
        Slide(title: "⚠️ Overdraft Fees Add Up",
              content: "Banks charge $25–$35 per overdraft transaction — some even charge daily fees!\n\nOptions:\n• Overdraft Protection — links to savings (small fee per use)\n• Overdraft Line of Credit — tiny loan (interest charged)\n• No-Overdraft — card simply declines, no fee\n\n✅ Best habit: keep a $100–$200 buffer in checking always.",
              imageName: nil,
              game: .math(question: "You overdraft 3 times at $30 each. Total fees paid ($)?", answer: 90),
              emoji: "⚠️"),
        Slide(title: "🐯 Tiger Market: Real Skills",
              content: "The Tiger Market mirrors real stock market investing!\n\nSkills you practice here translate directly:\n📊 Reading price trends (up/down arrows)\n⚖️ Risk vs reward analysis\n📈 Diversification (spread across industries)\n⏳ Patience — don't panic-sell!\n\nWhen you're ready for real investing, these habits are essential.",
              imageName: nil, game: nil, emoji: "🐯"),
        Slide(title: "🌟 Finance Wizard!",
              content: "Outstanding work! You now understand:\n\n📋 Zero-based budgeting — every dollar has a job\n💳 Credit cards — pay in full to avoid APR traps\n📊 Fixed vs Variable expenses\n⚠️ Overdraft fees cost real money\n🐯 Tiger Market = real skills, zero risk\n\nYou are financially dangerous! 🐯🔥",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    // MARK: - Lesson 4: Advanced Banking

    static func lesson4(_ band: AgeBand) -> [Slide] {
        switch band {
        case .young:  return lesson4Young
        case .mid:    return lesson4Mid
        case .older:  return lesson4Older
        }
    }

    private static let lesson4Young: [Slide] = [
        Slide(title: "⚖️ Borrowing Money",
              content: "Sometimes people BORROW money from a bank to buy big things — like a car or house!\n\nBut you must pay it ALL BACK, plus a little extra called INTEREST.\n\n⚠️ Borrowed money is NOT free money — it must always be paid back!",
              imageName: nil,
              game: .multipleChoice(question: "When you borrow money from a bank, you must...",
                                    options: ["Keep it forever", "Pay it all back plus interest", "Share it with friends"],
                                    correctIndex: 1),
              emoji: "⚖️"),
        Slide(title: "🔐 Protect Your Money",
              content: "Your money is YOUR money — protect it!\n\n🚫 NEVER share your PIN, password, or account numbers\n✅ Log out of apps when you're done\n📱 Use screen lock on your phone\n🚨 Tell a trusted adult if someone asks for your banking info",
              imageName: nil,
              game: .multipleChoice(question: "Someone online asks for your bank password. You should...",
                                    options: ["Send it to them", "Tell a trusted adult right away", "Ignore it and keep using the app"],
                                    correctIndex: 1),
              emoji: "🔐"),
        Slide(title: "🌟 Money Master!",
              content: "You've learned everything you need to get started!\n\n⚖️ Borrowing must always be paid back with interest\n🔐 Never share your account info — ever\n🏦 Banks keep your money safe\n\nKeep earning tiger stripes in each lesson and invest in the Tiger Market! 🐯🚀",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson4Mid: [Slide] = [
        Slide(title: "⚖️ Credit vs Debit",
              content: "DEBIT = YOUR money from your bank account. Spend only what you have.\nCREDIT = BORROWED money you pay back later.\n\nCredit can be helpful — but only if you ALWAYS pay on time. Late payments = interest charges + damaged credit score!",
              imageName: nil,
              game: .multipleChoice(question: "What happens if you don't pay your credit card bill on time?",
                                    options: ["Nothing happens", "You pay interest on the balance", "The bank pays it for you"],
                                    correctIndex: 1),
              emoji: "⚖️"),
        Slide(title: "📈 Compound Interest",
              content: "Regular interest: earn on your original amount only.\nCOMPOUND interest: earn interest ON your interest too — a money snowball!\n\nExample at 10% compound:\nYear 1: $1,000 → $1,100\nYear 2: $1,100 → $1,210\nYear 3: $1,210 → $1,331\n\nIt grows FASTER every year! 🚀",
              imageName: nil,
              game: .math(question: "$1,000 grows 10% to $1,100 in year 1. What is it after year 2 (× 1.10)?", answer: 1210),
              emoji: "📈"),
        Slide(title: "📊 Credit Score Intro",
              content: "Your CREDIT SCORE is a grade (300–850) that tells banks how responsible you are with money.\n\nHigher score = better loan rates = you save thousands over your lifetime!\n\nKey factors:\n✅ Pay every bill on time\n✅ Don't use too much of your credit limit\n✅ Keep accounts open long-term",
              imageName: nil,
              game: .multipleChoice(question: "What is the most important factor in building a good credit score?",
                                    options: ["Having many credit cards", "Paying bills on time", "Spending a lot of money"],
                                    correctIndex: 1),
              emoji: "📊"),
        Slide(title: "🔐 Banking Security",
              content: "Protect yourself from hackers and scammers:\n\n🎣 PHISHING – Fake messages pretending to be your bank\n🔑 Use UNIQUE passwords for every account\n📱 Enable TWO-FACTOR AUTHENTICATION (2FA)\n💳 Check bank statements monthly for unauthorized charges\n\n💡 Legitimate banks will NEVER ask for your full password!",
              imageName: nil,
              game: .multipleChoice(question: "A text says 'Your account is locked, click here to verify.' What do you do?",
                                    options: ["Click the link immediately", "Call your bank's official number directly", "Reply with your account details"],
                                    correctIndex: 1),
              emoji: "🔐"),
        Slide(title: "🌟 Advanced Banker!",
              content: "Look at everything you've mastered!\n\n⚖️ Credit vs debit — know the difference\n📈 Compound interest is the 8th wonder of the world\n📊 Credit score determines your financial opportunities\n🔐 Always protect your banking information\n\nNow dominate the Tiger Market with your stripes! 🐯💰",
              imageName: nil, game: nil, emoji: "🌟")
    ]

    private static let lesson4Older: [Slide] = [
        Slide(title: "⚖️ Credit Score Deep Dive",
              content: "FICO Score breakdown:\n\n35% – Payment history (most important!)\n30% – Credit utilization (keep below 30%)\n15% – Length of credit history\n10% – New credit inquiries\n10% – Credit mix (cards, loans, etc.)\n\n💡 Tip: Using $250 of a $1,000 limit = 25% utilization — good! Using $900 = 90% — bad!",
              imageName: nil,
              game: .multipleChoice(question: "What makes up the BIGGEST portion of your FICO credit score?",
                                    options: ["Credit utilization", "Payment history", "Length of credit history"],
                                    correctIndex: 1),
              emoji: "⚖️"),
        Slide(title: "💸 Taxes: The Basics",
              content: "TAXES are money paid to the government to fund schools, roads, healthcare, military, and more.\n\nMain types for individuals in the US:\n• FEDERAL INCOME TAX – paid to the US government (progressive rates: 10%–37%)\n• STATE INCOME TAX – varies by state (some states have NONE!)\n• FICA – Social Security (6.2%) + Medicare (1.45%) = 7.65% of income",
              imageName: nil,
              game: .multipleChoice(question: "What is the primary purpose of federal income taxes?",
                                    options: ["To make banks profit", "To fund government services and programs", "To pay credit card companies"],
                                    correctIndex: 1),
              emoji: "💸"),
        Slide(title: "📄 W-2 vs 1099",
              content: "W-2 EMPLOYEE – Your employer withholds taxes from every paycheck for you. You receive a W-2 form at tax time showing what was withheld.\n\n1099 CONTRACTOR – Self-employed or freelancer. You pay taxes yourself quarterly! Rate: ~15.3% self-employment tax + income tax.\n\n💡 As a 1099 contractor, save 25–30% of every payment for taxes!",
              imageName: nil,
              game: .multipleChoice(question: "Who is responsible for paying their own quarterly taxes?",
                                    options: ["W-2 employee", "1099 contractor / freelancer", "Both equally"],
                                    correctIndex: 1),
              emoji: "📄"),
        Slide(title: "🏠 Good Debt vs Bad Debt",
              content: "GOOD DEBT – Invests in your future value:\n• Student loans (higher earning power)\n• Mortgage (home builds equity)\n• Business loan (creates income)\n\nBAD DEBT – Loses value immediately:\n• Credit card debt at 22% APR for spending\n• Payday loans (300%–400% APR!) 😱\n• Car loan for a depreciating luxury vehicle",
              imageName: nil,
              game: .multipleChoice(question: "Which is typically considered 'good debt'?",
                                    options: ["Payday loan for rent", "A mortgage on a home that builds equity", "Credit card balance from restaurant meals"],
                                    correctIndex: 1),
              emoji: "🏠"),
        Slide(title: "📊 APR vs APY",
              content: "APR (Annual Percentage Rate) – Base rate without compounding. Lenders advertise this (looks lower).\n\nAPY (Annual Percentage Yield) – Includes the effect of compounding. Savers earn this (actually higher!).\n\nFormula: APY = (1 + APR/n)^n − 1\n\n💡 Always compare APYs for savings. Always check APR for loans.",
              imageName: nil,
              game: .math(question: "A savings account offers 6% APY on $1,000. How much interest do you earn in one year?", answer: 60),
              emoji: "📊"),
        Slide(title: "🔐 Identity Theft",
              content: "Warning signs you've been hacked:\n• Unfamiliar charges on statements\n• Bills for accounts you never opened\n• Credit score drops unexpectedly\n\nWhat to do immediately:\n1. Freeze your credit at all 3 bureaus (free!)\n2. Report to your bank immediately\n3. File a report at IdentityTheft.gov\n4. Monitor your credit for a full year",
              imageName: nil, game: nil, emoji: "🔐"),
        Slide(title: "🏆 Money Master!",
              content: "You've completed the most advanced financial literacy content!\n\n⚖️ FICO credit score — every component\n💸 Federal income taxes explained\n📄 W-2 vs 1099 — employee vs contractor\n🏠 Good debt vs bad debt\n📊 APR vs APY — the real math\n🔐 Identity theft protection\n\nYou are a TRUE MONEY MASTER! 🐯🏆\n\nNow dominate the Tiger Market with your stripes!",
              imageName: nil, game: nil, emoji: "🏆")
    ]
}
