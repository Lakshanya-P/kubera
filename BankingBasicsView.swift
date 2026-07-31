import SwiftUI

// MARK: - Main View

struct BankingBasicsView: View {

    @State private var selection = 0

    // Bitmask of completed lessons (for the "Completed" badges).
    @AppStorage("bankDoneMask") private var doneMask = 0

    private let lessons: [(title: String, lesson: LessonType, color: Color, icon: String)] = [
        ("Banking Basics", .lesson1, Theme.primary, "building.columns.fill"),
        ("Saving & Goals", .lesson2, Theme.secondary, "target"),
        ("Budgeting & Debit Cards", .lesson3, Theme.purple, "creditcard.fill"),
        ("Advanced Banking", .lesson4, Theme.coral, "chart.line.uptrend.xyaxis")
    ]

    private func isDone(_ number: Int) -> Bool { doneMask & (1 << (number - 1)) != 0 }

    var body: some View {
        ZStack {
            AppBackground(image: "background4")

            GeometryReader { geo in
                VStack(spacing: Theme.Space.m) {

                    Text("Banking Lessons")
                        .font(.title.weight(.heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink)

                    // Swipeable slideshow — about a quarter of the screen tall.
                    TabView(selection: $selection) {
                        ForEach(lessons.indices, id: \.self) { i in
                            lessonSlide(lessons[i])
                                .padding(.horizontal, Theme.Space.xs)
                                .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: max(geo.size.height * 0.25, 190))
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

            Spacer(minLength: 0)

            NavigationLink {
                LessonView(lesson: item.lesson)
            } label: {
                Text(done ? "Review Lesson" : "Start Lesson")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.color)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Space.m)
        .padding(.bottom, Theme.Space.m)   // room for the page dots
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.color, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .shadow(color: item.color.opacity(0.35), radius: 10, y: 6)
    }
}

// MARK: - Lesson Types

enum LessonType {
    case lesson1, lesson2, lesson3, lesson4

    var slides: [Slide] {
        switch self {
        case .lesson1: return LessonContent.lesson1
        case .lesson2: return LessonContent.lesson2
        case .lesson3: return LessonContent.lesson3
        case .lesson4: return LessonContent.lesson4
        }
    }

    var number: Int {
        switch self {
        case .lesson1: return 1
        case .lesson2: return 2
        case .lesson3: return 3
        case .lesson4: return 4
        }
    }
}

// MARK: - Lesson View with Next Button

struct LessonView: View {

    let lesson: LessonType
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss

    @AppStorage("bankDoneMask") private var doneMask = 0
    @AppStorage("bankLastCompleted") private var lastCompleted = 0

    private var isLastSlide: Bool { currentIndex >= lesson.slides.count - 1 }

    var body: some View {
        ZStack {
            AppBackground(image: "background4")

            VStack(spacing: Theme.Space.m) {

                ProgressView(value: Double(currentIndex + 1), total: Double(lesson.slides.count))
                    .tint(Theme.primary)

                SlideView(slide: lesson.slides[currentIndex])
                    .id(currentIndex)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))

                Button {
                    if isLastSlide {
                        completeLesson()
                    } else {
                        withAnimation(.easeInOut) { currentIndex += 1 }
                    }
                } label: {
                    Text(isLastSlide ? "Finish 🎉" : "Next")
                }
                .buttonStyle(PrimaryButtonStyle(fill: isLastSlide ? Theme.secondary : Theme.primary))
            }
            .responsiveWidth()
            .padding()
        }
        .navigationTitle("Lesson")
        .inlineNavigationTitle()
    }

    private func completeLesson() {
        doneMask |= (1 << (lesson.number - 1))
        lastCompleted = lesson.number
        dismiss()
    }
}


// MARK: - Lesson Content

struct LessonContent {

    // Lesson 1: Banking Basics
    static let lesson1: [Slide] = [
        Slide(
            title: "Welcome to Banking!",
            content: """
Banks are safe places to store your money. A checking account is for your everyday spending, while a savings account helps you grow your money over time.
Deposits add money, withdrawals take money out. Always keep track of your balance!
""",
            imageName: "bank",
            game: nil
        ),
        Slide(
            title: "How Checking Accounts Work",
            content: """
Your checking account lets you pay bills, buy items, and withdraw cash. It’s like a digital wallet!
Remember: Always check your balance before spending.
""",
            imageName: "money",
            game: .multipleChoice(
                question: "Which action takes money out of a checking account?",
                options: ["Deposit", "Withdrawal"],
                correctIndex: 1
            )
        ),
        Slide(
            title: "Deposits & Withdrawals",
            content: """
Deposits make your balance grow. Withdrawals reduce it.
Banks provide ATM, online banking, and teller services to help you manage your money safely.
""",
            imageName: "atm",
            game: .math(
                question: "You deposit $50 and withdraw $20. How much remains?",
                answer: 30
            )
        ),
        Slide(
            title: "Smart Spending",
            content: """
Being smart with money means spending less than you earn. Always save a portion for the future!
Budgeting is key: Track your income and plan your spending carefully.
""",
            imageName: "budget",
            game: .multipleChoice(
                question: "Which is the smartest habit?",
                options: ["Spend everything", "Save some", "Ignore budget"],
                correctIndex: 1
            )
        ),
        Slide(
            title: "Summary & Tips",
            content: """
✅ Banks keep your money safe
✅ Checking accounts = everyday spending
✅ Savings accounts = grow your money
✅ Always monitor your transactions
✅ Budget and save consistently
""",
            imageName: "piggyBank",
            game: nil
        )
    ]

    // Lesson 2: Saving & Goals
    static let lesson2: [Slide] = [
        Slide(
            title: "Why Save Money?",
            content: """
Saving money helps you reach goals, be prepared for emergencies, and reduce stress.
Start small—even saving $1 a day makes a difference over time.
""",
            imageName: "savings",
            game: nil
        ),
        Slide(
            title: "Needs vs Wants",
            content: """
Needs are essential for survival—like food, shelter, and clothing.
Wants are extras that make life fun—like toys, candy, or games.
Understanding this helps you prioritize your spending.
""",
            imageName: "needsVsWants",
            game: .needsVsWants
        ),
        Slide(
            title: "Setting Goals",
            content: """
Set realistic goals for what you want to save for: short-term (toys), medium-term (bike), long-term (college).
Track your progress regularly and celebrate milestones!
""",
            imageName: "goals",
            game: .math(
                question: "You want a bike for $200. You save $50 per month. How many months to afford it?",
                answer: 4
            )
        ),
        Slide(
            title: "Interest Matters",
            content: """
Banks can pay interest on your savings—extra money just for keeping it there!
Even small interest rates add up over time thanks to compounding.
""",
            imageName: "interest",
            game: .math(
                question: "You save $100 at 5% interest. Total after one period?",
                answer: 105
            )
        ),
        Slide(
            title: "Summary & Tips",
            content: """
✅ Save regularly
✅ Prioritize needs over wants
✅ Set achievable goals
✅ Learn about interest and compounding
✅ Celebrate progress!
""",
            imageName: "piggyBankFull",
            game: nil
        )
    ]

    // Lesson 3: Budgeting & Debit Cards
    static let lesson3: [Slide] = [
        Slide(
            title: "What is a Debit Card?",
            content: """
A debit card lets you spend the money in your checking account safely.
It’s convenient, secure, and helps you track spending digitally.
""",
            imageName: "debitCard",
            game: nil
        ),
        Slide(
            title: "Creating a Budget",
            content: """
A budget is a plan for your money: track income, expenses, and savings.
Use categories: needs, wants, and savings. Adjust as your goals change.
""",
            imageName: "budgetPlan",
            game: .multipleChoice(
                question: "Which is part of a budget?",
                options: ["Wants", "Needs", "Savings", "All of the above"],
                correctIndex: 3
            )
        ),
        Slide(
            title: "Spending Wisely",
            content: """
Always compare prices, avoid impulse buys, and pay attention to recurring expenses.
Smart spending protects your savings and helps reach goals faster.
""",
            imageName: "shopping",
            game: .math(
                question: "You have $100, spend $30 on food, $20 on games. How much left?",
                answer: 50
            )
        ),
        Slide(
            title: "Summary & Tips",
            content: """
✅ Debit cards are safe and convenient
✅ Track all spending
✅ Categorize income and expenses
✅ Stick to your budget
✅ Adjust as goals change
""",
            imageName: "wallet",
            game: nil
        )
    ]

    // Lesson 4: Advanced Banking
    static let lesson4: [Slide] = [
        Slide(
            title: "Credit vs Debit",
            content: """
Debit is your money. Credit is borrowed money that must be paid back with interest.
Use credit wisely to avoid debt.
""",
            imageName: "creditVsDebit",
            game: .multipleChoice(
                question: "Credit must be:",
                options: ["Ignored", "Paid back", "Saved"],
                correctIndex: 1
            )
        ),
        Slide(
            title: "Compound Interest",
            content: """
Compound interest is earning money on your money AND on interest it has earned.
It helps savings grow faster over time.
""",
            imageName: "compoundInterest",
            game: .math(
                question: "10% of $200 equals?",
                answer: 20
            )
        ),
        Slide(
            title: "Financial Safety",
            content: """
Always monitor accounts, use strong passwords, and avoid sharing sensitive info.
Fraud prevention is an important skill for everyone!
""",
            imageName: "security",
            game: nil
        ),
        Slide(
            title: "Summary & Tips",
            content: """
✅ Debit vs credit understanding
✅ Use compound interest to your advantage
✅ Keep accounts secure
✅ Track spending and saving
✅ Stay financially literate!
""",
            imageName: "savingsGoals",
            game: nil
        )
    ]
}
