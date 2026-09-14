//
//  LogMealView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//
//  LogMealView.swift

import SwiftUI

struct LogMealView: View {
    @EnvironmentObject var viewModel: NutritionViewModel
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @AppStorage("energyUnit") private var energyUnitRaw: String = EnergyUnit.calories.rawValue

    @State private var dishName: String = ""
    @State private var mealType: MealType = .breakfast
    @State private var energyInput: String = ""
    @State private var proteinGrams: String = ""
    @State private var carbGrams: String = ""
    @State private var fatGrams: String = ""
    @State private var showMacroDetails = false
    @State private var saveForLater = false

    private var energyUnit: EnergyUnit {
        EnergyUnit(rawValue: energyUnitRaw) ?? .calories
    }

    var body: some View {
        NavigationView {
            Form {
                if !viewModel.savedMeals.isEmpty {
                    Section("Quick Log") {
                        ForEach(viewModel.savedMeals) { meal in
                            Button {
                                logSavedMeal(meal)
                            } label: {
                                HStack {
                                    Text(meal.dishName)
                                    Spacer()
                                    Text(energyUnit.format(fromKilocalories: meal.calories))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Meal Details") {
                    TextField("Dish name", text: $dishName)

                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    TextField(energyFieldPlaceholder, text: $energyInput)
                        .keyboardType(.decimalPad)
                }

                Section {
                    DisclosureGroup("Add macro details (optional)", isExpanded: $showMacroDetails) {
                        macroField(label: "Protein (g)", value: $proteinGrams)
                        macroField(label: "Carbs (g)", value: $carbGrams)
                        macroField(label: "Fat (g)", value: $fatGrams)
                    }
                }

                Section {
                    Toggle("Save this meal for quick logging later", isOn: $saveForLater)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Log Meal") {
                        submit()
                    }
                }
            }
            .navigationTitle("Log Food")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private var energyFieldPlaceholder: String {
        switch energyUnit {
        case .calories: return "Calories (e.g. 500)"
        case .kilojoules: return "Kilojoules (e.g. 2092)"
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

    private func logSavedMeal(_ meal: SavedMeal) {
        viewModel.logSavedMeal(meal, mealType: mealType)
        if viewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func submit() {
        guard let enteredEnergy = Double(energyInput) else {
            viewModel.errorMessage = "Please enter the \(energyUnit.displayName.lowercased()) for this meal."
            return
        }

        let calorieValue = energyUnit.toKilocalories(enteredEnergy)
        let proteinValue = Double(proteinGrams) ?? 0
        let carbValue = Double(carbGrams) ?? 0
        let fatValue = Double(fatGrams) ?? 0

        viewModel.logMeal(
            dishName: dishName,
            mealType: mealType,
            calories: calorieValue,
            proteinGrams: proteinValue,
            carbGrams: carbValue,
            fatGrams: fatValue
        )

        guard viewModel.errorMessage == nil else { return }

        if saveForLater {
            viewModel.saveAsTemplate(
                dishName: dishName,
                calories: calorieValue,
                proteinGrams: proteinValue,
                carbGrams: carbValue,
                fatGrams: fatValue
            )
        }

        presentationMode.wrappedValue.dismiss()
    }
}

struct LogMealView_Previews: PreviewProvider {
    static var previews: some View {
        LogMealView().environmentObject(NutritionViewModel())
    }
}
