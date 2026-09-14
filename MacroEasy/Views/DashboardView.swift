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
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .onAppear {
                viewModel.refreshDashboard()
            }
        }
    }

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

    private func progressSection(_ progress: DailyNutritionProgress) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(Int(progress.caloriesConsumed)) / \(Int(progress.caloriesTarget))")
                    .font(.largeTitle)
                    .bold()
                Text("Calories")
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                ForEach(progress.macroProgress, id: \.macro.rawValue) { macroProgress in
                    NavigationLink(destination: MacroDetailView(macro: macroProgress.macro)) {
                        MacroRingView(progress: macroProgress)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

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
}

private struct MacroRingView: View {
    let progress: MacroProgress

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(progress.progressFraction, 1.0))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress.consumedGrams))g")
                    .font(.caption)
                    .bold()
            }
            .frame(width: 70, height: 70)

            Text(progress.macro.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var ringColor: Color {
        switch progress.macro {
        case .protein: return .red
        case .carbohydrate: return .green
        case .fat: return .yellow
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView().environmentObject(NutritionViewModel())
    }
}
