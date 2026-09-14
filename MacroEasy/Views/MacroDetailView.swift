//
//  MacroDetailView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import SwiftUI

struct MacroDetailView: View {
    let macro: Macronutrient
    @EnvironmentObject var viewModel: NutritionViewModel

    private var educationContent: MacronutrientEducationContent? {
        MacronutrientEducationContent.all[macro]
    }

    private var assessment: MacronutrientAdequacyAssessment? {
        viewModel.adequacyAssessment(for: macro)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let assessment {
                    statusCard(assessment)
                }

                mealBreakdownSection

                if let content = educationContent {
                    educationSection(content)
                }
            }
            .padding()
        }
        .navigationTitle(macro.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusCard(_ assessment: MacronutrientAdequacyAssessment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(assessment.status.displayLabel)
                .font(.headline)
                .foregroundColor(statusColor(assessment.status))
            Text(assessment.explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(statusColor(assessment.status).opacity(0.1))
        .cornerRadius(10)
    }

    private func statusColor(_ status: AdequacyStatus) -> Color {
        switch status {
        case .low: return .orange
        case .onTrack: return .green
        case .high: return .red
        }
    }

    private var mealBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's \(macro.displayName) by Meal")
                .font(.headline)

            ForEach(viewModel.gramsByMealType(for: macro), id: \.mealType) { breakdown in
                HStack {
                    Text(breakdown.mealType.displayName)
                    Spacer()
                    Text("\(Int(breakdown.grams))g")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func educationSection(_ content: MacronutrientEducationContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Why do I need it?")
                    .font(.headline)
                Text(content.whyYouNeedIt)
                    .font(.subheadline)
            }

            if let assessment, !assessment.foodSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Good sources to try")
                        .font(.headline)
                    ForEach(assessment.foodSuggestions, id: \.self) { food in
                        Text("• \(food)")
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

struct MacroDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MacroDetailView(macro: .protein)
                .environmentObject(NutritionViewModel())
        }
    }
}
