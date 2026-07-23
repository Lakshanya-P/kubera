import SwiftUI

// MARK: - Main View

struct BankingBasicsView: View {
    
    @State private var showTutorialSheet = false
    
    var body: some View {
        ZStack{
            Image("background4") 
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            NavigationStack {
                VStack(spacing: 20) {
                    
                    Text("Banking Lessons!")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.top)
                        .foregroundColor(.black)
                    
                    // Two-column grid for lessons
                    let columns = [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        
                        NavigationLink(destination: LessonView(lesson: .lesson1)) {
                            LessonButton(title: "Lesson 1: Banking Basics", color: Color.fromHex("#4281f5"))
                                .frame(maxWidth: .infinity, minHeight: 120) // fill space
                        }
                        
                        NavigationLink(destination: LessonView(lesson: .lesson2)) {
                            LessonButton(title: "Lesson 2: Saving & Goals", color: Color.fromHex("#34c796"))
                                .frame(maxWidth: .infinity, minHeight: 120)
                        }
                        
                        NavigationLink(destination: LessonView(lesson: .lesson3)) {
                            LessonButton(title: "Lesson 3: Budgeting & Debit Cards", color: Color.fromHex("#5ae0c1"))
                                .frame(maxWidth: .infinity, minHeight: 120)
                        }
                        
                        NavigationLink(destination: LessonView(lesson: .lesson4)) {
                            LessonButton(title: "Lesson 4: Advanced Banking", color: Color.fromHex("#42b8fc"))
                                .frame(maxWidth: .infinity, minHeight: 120)
                        }
                        
                        
                        
                    }
                    .padding()
                    
                    Button {
                        showTutorialSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                            Text(" Tutorial?")
                                .bold()
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: 200)
                        .padding()
                        .background(Color.fromHex("#27ab8c"))
                        .cornerRadius(12)
                    }
                    .sheet(isPresented: $showTutorialSheet) {
                        TutorialSheetView1()
                    }
                    .frame(maxHeight: .infinity) // fill remaining vertical space
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

// MARK: - Lesson Button

struct LessonButton: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(color)
            .cornerRadius(15)
            .shadow(radius: 5)
            .multilineTextAlignment(.center)
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
}

// MARK: - Lesson View with Next Button

struct LessonView: View {
    
    let lesson: LessonType
    @State private var currentIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            
            ProgressView(value: Double(currentIndex + 1),
                         total: Double(lesson.slides.count))
            .padding()
            
            // Display current slide
            SlideView(slide: lesson.slides[currentIndex])
                .animation(.easeInOut, value: currentIndex)
                .transition(.slide)
            
            Spacer()
            
            // Next / Finish button
            Button(action: {
                if currentIndex < lesson.slides.count - 1 {
                    currentIndex += 1
                } else {
                    dismiss()
                }
            }) {
                Text(currentIndex < lesson.slides.count - 1 ? "Next ➡️" : "Finish ✅")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
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
