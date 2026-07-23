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
            Image("background3") // Your background image
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: Goal Display
                    if !goals.isEmpty, selectedIndex < goals.count {
                        HStack {
                            Button {
                                if selectedIndex > 0 { selectedIndex -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                            .disabled(selectedIndex == 0)
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Text(goals[selectedIndex].title)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.black)
                                
                                Chart {
                                    SectorMark(
                                        angle: .value("Progress",
                                                      min(goals[selectedIndex].savedAmount, goals[selectedIndex].targetAmount)),
                                        innerRadius: .ratio(0.7)
                                    )
                                    .foregroundStyle(.green)
                                    
                                    SectorMark(
                                        angle: .value("Remaining",
                                                      max(goals[selectedIndex].targetAmount - goals[selectedIndex].savedAmount, 0)),
                                        innerRadius: .ratio(0.7)
                                    )
                                    .foregroundStyle(.gray.opacity(0.3))
                                }
                                .frame(height: 200)
                                
                                Text("$\(goals[selectedIndex].savedAmount, specifier: "%.2f") / $\(goals[selectedIndex].targetAmount, specifier: "%.2f")")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text("Start: \(formattedDate(goals[selectedIndex].startDate))")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                                
                                Text("Target: \(formattedDate(goals[selectedIndex].endDate))")
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button {
                                if selectedIndex < goals.count - 1 { selectedIndex += 1 }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                            .disabled(selectedIndex == goals.count - 1)
                        }
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(16)
                    } else {
                        Text("No goals yet!")
                            .foregroundColor(.gray)
                            .padding()
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // MARK: Add Goal
                    VStack(spacing: 12) {
                        Text("Add Goal")
                            .bold()
                            .foregroundColor(.black)
                        
                        ZStack(alignment: .leading) {
                            if newGoalTitle.isEmpty {
                                Text("Goal Name")
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 8)
                            }
                            TextField("", text: $newGoalTitle)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.6)))
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        ZStack(alignment: .leading) {
                            if newGoalTarget.isEmpty {
                                Text("Target Amount")
                                    .foregroundColor(.black.opacity(0.7))
                                    .padding(.leading, 8)
                            }
                            TextField("", text: $newGoalTarget)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.6)))
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        DatePicker("Target Completion Date", selection: $newGoalEndDate, displayedComponents: .date)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.6)))
                            .foregroundColor(.black)
                        
                        Button("Add Goal") {
                            addGoal()
                        }
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(16)
                    
                    Divider()
                    
                    // MARK: Add Money Toward Goal
                    if !goals.isEmpty {
                        VStack(spacing: 12) {
                            Text("Add Money Toward Goal")
                                .bold()
                                .foregroundColor(.black)
                            
                            ZStack(alignment: .leading) {
                                if addAmountText.isEmpty {
                                    Text("Amount")
                                        .foregroundColor(.black.opacity(0.7))
                                        .padding(.leading, 8)
                                }
                                TextField("", text: $addAmountText)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.6)))
                                    .foregroundColor(.black)
                                    .accentColor(.black)
                            }
                            
                            Button("Add to Goal") {
                                addToGoal()
                            }
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(goals.isEmpty)
                        }
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Goals")
        .alert("Notice", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
