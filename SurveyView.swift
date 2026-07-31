import SwiftUI

struct SurveyView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]

    @AppStorage("survey_name") private var name: String = ""
    @AppStorage("survey_age") private var age: Int = 13
    @AppStorage("survey_hasChecking") private var hasCheckingAccountStored: Bool?

    var body: some View {
        ZStack {
            AppBackground(image: "background2")

            CenteredScrollView(maxWidth: 640) {
                VStack(spacing: Theme.Space.l) {

                    // MARK: About You
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionTitle("About You")

                        KidTextField(placeholder: "Enter your name", text: $name)

                        Stepper("Age: \(age)", value: $age, in: 0...99)
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 4)

                        if age < 13 {
                            Label("You must be 13 or older to proceed.", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.coral)
                        }
                    }
                    .card()

                    // MARK: Banking Experience
                    VStack(alignment: .leading, spacing: Theme.Space.s) {
                        SectionTitle("Banking Experience")
                        QuestionView(question: "Do you have a checking account?", selection: $hasCheckingAccountStored)
                    }
                    .card()

                    // MARK: Continue
                    NavigationLink {
                        nextDestination
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary, icon: "arrow.right"))
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.5)
                }
            }
        }
        .navigationTitle("Your Information")
    }

    var canContinue: Bool {
        age >= 13 && hasCheckingAccountStored != nil
    }

    @ViewBuilder
    var nextDestination: some View {
        if hasCheckingAccountStored == true {
            DashboardView(items: $items, mainBalance: $mainBalance, savingsBalance: $savingsBalance, goals: $goals)
        } else {
            BankingBasicsView()
        }
    }
}

struct QuestionView: View {
    let question: String
    @Binding var selection: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            Text(question)
                .font(.headline)
                .foregroundStyle(Theme.ink)

            HStack(spacing: Theme.Space.s) {
                optionButton(title: "Yes", value: true)
                optionButton(title: "No", value: false)
            }
        }
    }

    private func optionButton(title: String, value: Bool) -> some View {
        let selected = selection == value
        return Button {
            selection = value
        } label: {
            Text(title)
                .fontWeight(.bold)
                .foregroundStyle(selected ? .white : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    selected ? Theme.primary : Color.fromHex("#F1F5FB"),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}
