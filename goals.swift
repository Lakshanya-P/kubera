import SwiftUI
import Charts

struct Goal: Identifiable {
    let id = UUID()
    var title: String
    var targetAmount: Double
    var savedAmount: Double
    var startDate: Date
    var endDate: Date
}

struct GoalsView: View {

    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var goals: [Goal]
    @State private var selectedIndex: Int = 0

    @State private var newGoalTitle = ""
    @State private var newGoalTarget = ""
    @State private var newGoalEndDate = Date()

    @State private var addAmountText = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            AppBackground(image: "background3")

            CenteredScrollView {
                VStack(spacing: Theme.Space.l) {

                    goalDisplay
                        .tutorialAnchor("goal.display")

                    // MARK: Add Goal
                    VStack(spacing: Theme.Space.s) {
                        SectionTitle("New Goal")
                        KidTextField(placeholder: "Goal name (e.g. New Bike)", text: $newGoalTitle)
                        KidTextField(placeholder: "Target amount", text: $newGoalTarget, keyboard: .decimal)

                        DatePicker("Target date", selection: $newGoalEndDate, displayedComponents: .date)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 4)

                        Button("Add Goal") { addGoal() }
                            .buttonStyle(PrimaryButtonStyle(fill: Theme.primary, icon: "plus"))
                    }
                    .card()
                    .tutorialAnchor("goal.new")

                    // MARK: Add Money Toward Goal
                    if !goals.isEmpty {
                        VStack(spacing: Theme.Space.s) {
                            SectionTitle("Add to This Goal")
                            KidTextField(placeholder: "Amount to save", text: $addAmountText, keyboard: .decimal)
                            Button("Add to Goal") { addToGoal() }
                                .buttonStyle(PrimaryButtonStyle(fill: Theme.secondary, icon: "arrow.up"))
                        }
                        .card()
                    }
                }
            }
        }
        .navigationTitle("Goals")
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .coachMarks(.goals)
        .keyboardDoneButton()
    }

    // MARK: - Goal display

    @ViewBuilder
    private var goalDisplay: some View {
        if !goals.isEmpty, selectedIndex < goals.count {
            let goal = goals[selectedIndex]
            let progress = goal.targetAmount > 0 ? min(goal.savedAmount / goal.targetAmount, 1) : 0

            VStack(spacing: Theme.Space.m) {
                HStack {
                    navButton(icon: "chevron.left", disabled: selectedIndex == 0) {
                        if selectedIndex > 0 { selectedIndex -= 1 }
                    }
                    Spacer()
                    Text(goal.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Spacer()
                    navButton(icon: "chevron.right", disabled: selectedIndex == goals.count - 1) {
                        if selectedIndex < goals.count - 1 { selectedIndex += 1 }
                    }
                }

                ZStack {
                    Chart {
                        SectorMark(angle: .value("Saved", goal.savedAmount), innerRadius: .ratio(0.72))
                            .foregroundStyle(Theme.secondary)
                        SectorMark(angle: .value("Remaining", max(goal.targetAmount - goal.savedAmount, 0)), innerRadius: .ratio(0.72))
                            .foregroundStyle(Theme.ink.opacity(0.12))
                    }
                    .frame(height: 200)

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.ink)
                        Text("saved")
                            .font(.caption)
                            .foregroundStyle(Theme.ink.opacity(0.5))
                    }
                }

                Text("\(goal.savedAmount, format: .currency(code: "USD")) of \(goal.targetAmount, format: .currency(code: "USD"))")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                Text("Target date: \(formattedDate(goal.endDate))")
                    .font(.caption)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .card()
        } else {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "target")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text("No goals yet!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text("Create your first saving goal below.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .card()
        }
    }

    private func navButton(icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(disabled ? Theme.ink.opacity(0.25) : Theme.primary)
                .frame(width: 44, height: 44)
                .background(Color.fromHex("#F1F5FB"), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private func addGoal() {
        guard let target = Double(newGoalTarget), target > 0, !newGoalTitle.isEmpty else { return }

        let newGoal = Goal(
            title: newGoalTitle,
            targetAmount: target,
            savedAmount: 0,
            startDate: Date(),
            endDate: newGoalEndDate
        )

        goals.append(newGoal)
        newGoalTitle = ""
        newGoalTarget = ""
        newGoalEndDate = Date()
        selectedIndex = goals.count - 1
    }

    private func addToGoal() {
        guard let amount = Double(addAmountText), amount > 0 else { return }
        guard !goals.isEmpty else { return }

        if mainBalance < amount {
            alertMessage = "You do not have enough balance."
            showAlert = true
            return
        }

        mainBalance -= amount
        goals[selectedIndex].savedAmount += amount
        addAmountText = ""
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }
}
