//
//  DashboardView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: NutritionViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.needsTargets {
                        noTargetsPrompt
                    } else if let progress = viewModel.dailyProgress {
                        progressSection(progress)

                        if progress.hasIncompleteMacroData {
                            incompleteMacroWarning(count: progress.mealsMissingMacros)
                        }

                        if !viewModel.insights.isEmpty {
                            insightsSection
                        }

                        if !progress.entries.isEmpty {
                            todaysMealsSection(progress.entries)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
                .padding(.bottom, 80) // clears the custom tab bar
            }
            .navigationTitle("Today")
            .onAppear {
                viewModel.refreshDashboard()
            }
        }
    }

    // MARK: - No Targets

    private var noTargetsPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Set your daily goals to start tracking your progress.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Text("Go to the Targets tab to get started.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    // MARK: - Progress (Calorie Ring + Macro Rows)

    private func progressSection(_ progress: DailyNutritionProgress) -> some View {
        HStack(alignment: .center, spacing: 20) {
            CalorieRingView(consumed: progress.caloriesConsumed, target: progress.caloriesTarget)
                .frame(width: 170, height: 170)

            VStack(spacing: 12) {
                ForEach(progress.macroProgress, id: \.macro.rawValue) { macroProgress in
                    NavigationLink(destination: MacroDetailView(macro: macroProgress.macro)) {
                        MacroGlassRow(progress: macroProgress)
                    }
                    .buttonStyle(GlassCardButtonStyle())
                }
            }
        }
    }

    // MARK: - Incomplete Macro Warning

    private func incompleteMacroWarning(count: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("\(count) meal\(count == 1 ? "" : "s") logged today without macro details — your macro breakdown may be incomplete.")
                .font(.footnote)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
            ForEach(viewModel.insights) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconName(for: insight.trendDirection))
                        .foregroundColor(iconColor(for: insight.trendDirection))
                    Text(insight.message)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func iconName(for trend: DietaryInsight.TrendDirection) -> String {
        switch trend {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .steady: return "checkmark.circle"
        }
    }

    private func iconColor(for trend: DietaryInsight.TrendDirection) -> Color {
        switch trend {
        case .steady: return .green
        default: return .blue
        }
    }

    // MARK: - Today's Meals

    private func todaysMealsSection(_ entries: [MealEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.headline)

            ForEach(entries.sorted(by: { $0.loggedAt > $1.loggedAt })) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(entry.dishName)
                                .font(.subheadline)
                                .bold()
                            if !entry.macrosProvided {
                                Image(systemName: "exclamationmark.circle")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        Text("\(entry.mealType.displayName) · \(timeFormatter.string(from: entry.loggedAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(Int(entry.calories)) cal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        viewModel.deleteMeal(id: entry.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)

                if entry.id != entries.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

// MARK: - Calorie Ring

private struct CalorieRingView: View {
    let consumed: Double
    let target: Double

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(consumed))")
                    .font(.system(size: 30, weight: .bold))
                Text("/ \(Int(target))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Calories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Macro Glass Row

private struct MacroGlassRow: View {
    let progress: MacroProgress

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(progress.progressFraction, 1.0))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(Int(progress.consumedGrams))g")
                    .font(.subheadline)
                    .bold()
                Text(progress.macro.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 150)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var ringColor: Color {
        switch progress.macro {
        case .protein: return .red
        case .carbohydrate: return .green
        case .fat: return .yellow
        }
    }
}

// MARK: - Button Style

private struct GlassCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView().environmentObject(NutritionViewModel())
    }
}
