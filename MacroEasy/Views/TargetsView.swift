//
//  TargetsView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//


import SwiftUI

struct TargetsView: View {
    @EnvironmentObject var viewModel: NutritionViewModel

    @State private var selectedGoal: NutritionGoal = .maintain
    @State private var calories: String = ""
    @State private var proteinGrams: String = ""
    @State private var carbGrams: String = ""
    @State private var fatGrams: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Your Goal") {
                    Picker("Goal", selection: $selectedGoal) {
                        ForEach(NutritionGoal.allCases) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedGoal) {
                        applySuggestedMacros()
                    }
                }

                Section("Daily Calories") {
                    TextField("e.g. 2000", text: $calories)
                        .keyboardType(.numberPad)
                        .onChange(of: calories) {
                            applySuggestedMacros()
                        }
                }

                Section {
                    macroField(label: "Protein (g)", value: $proteinGrams)
                    macroField(label: "Carbs (g)", value: $carbGrams)
                    macroField(label: "Fat (g)", value: $fatGrams)
                } header: {
                    Text("Macro Targets")
                } footer: {
                    Text("We've suggested a starting split based on your goal — feel free to adjust it.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Save Goals") {
                        saveTargets()
                    }
                }
            }
            .navigationTitle("Targets")
            .onAppear {
                loadExistingTargets()
            }
        }
    }

    private func macroField(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func loadExistingTargets() {
        guard let existing = viewModel.targets else {
            applySuggestedMacros()
            return
        }
        selectedGoal = existing.goal
        calories = String(Int(existing.calories))
        proteinGrams = String(Int(existing.proteinGrams))
        carbGrams = String(Int(existing.carbGrams))
        fatGrams = String(Int(existing.fatGrams))
    }

    private func applySuggestedMacros() {
        guard let calorieValue = Double(calories), calorieValue > 0 else { return }
        let suggestion = viewModel.suggestedMacros(for: selectedGoal, calories: calorieValue)
        proteinGrams = String(Int(suggestion.proteinGrams))
        carbGrams = String(Int(suggestion.carbGrams))
        fatGrams = String(Int(suggestion.fatGrams))
    }

    private func saveTargets() {
        guard let calorieValue = Double(calories),
              let proteinValue = Double(proteinGrams),
              let carbValue = Double(carbGrams),
              let fatValue = Double(fatGrams) else {
            viewModel.errorMessage = "Please fill in all fields with valid numbers."
            return
        }

        viewModel.setTargets(
            goal: selectedGoal,
            calories: calorieValue,
            proteinGrams: proteinValue,
            carbGrams: carbValue,
            fatGrams: fatValue
        )
    }
}

struct TargetsView_Previews: PreviewProvider {
    static var previews: some View {
        TargetsView().environmentObject(NutritionViewModel())
    }
}
