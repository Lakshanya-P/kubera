import SwiftUI

struct SurveyView: View {
    
    @Binding var items: [BudgetItem]
    @Binding var mainBalance: Double
    @Binding var savingsBalance: Double
    @Binding var goals: [Goal]
    
    @AppStorage("survey_name") private var name: String = ""
    @AppStorage("survey_age") private var age: Int = 13
    @AppStorage("survey_hasChecking") private var hasCheckingAccountStored: Bool?
    
    @State private var showAgeAlert: Bool = false
    @State private var showBankingLesson: Bool = false
    
    var body: some View {
        ZStack {
            Image("background2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("About You")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.black)
                        
                        ZStack(alignment: .leading) {
                            if name.isEmpty {
                                Text("Enter your name")
                                    .foregroundColor(Color.black.opacity(0.9))
                                    .frame(maxWidth:.infinity, alignment:.center)
                            }
                            TextField("", text: $name)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .foregroundColor(.black)
                                .accentColor(.black)
                        }
                        
                        Stepper("Age: \(age)", value: $age, in: 0...99)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(12)
                            .foregroundColor(.black.opacity(0.8))
                        
                        if age < 13 {
                            Text("You must be 13 or older to proceed.")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Banking Experience")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth:.infinity, alignment:.center)
                            .foregroundColor(.black)
                        
                        QuestionView(question: "Do you have a checking account?", selection: $hasCheckingAccountStored)
                    }
                    .padding()
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(16)
                    
                    Button {
                        if age < 13 {
                            showAgeAlert = true
                        } else if hasCheckingAccountStored == false {
                            showBankingLesson = true
                        }
                    } label: {
                        NavigationLink(destination: nextDestination) {
                            Text("Continue")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canContinue ? Color.green.opacity(0.85) : Color.gray.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!canContinue)
                    }
                    .padding(.horizontal)
                    .alert("You must be 13 or older to proceed.", isPresented: $showAgeAlert) {
                        Button("OK", role: .cancel) { }
                    }
                    .sheet(isPresented: $showBankingLesson) {
                        BankingBasicsView()
                    }
                    
                    Spacer()
                }
                .padding()
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
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.headline)
            
            HStack(spacing: 12) {
                optionButton(title: "Yes", value: true)
                optionButton(title: "No", value: false)
            }
        }
    }
    
    private func optionButton(title: String, value: Bool) -> some View {
        Button {
            selection = value
        } label: {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(selection == value ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selection == value ? Color.blue : Color.gray.opacity(0.25))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
