//
//  HistoryView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//


import SwiftUI
import Charts

enum HistoryMetric: Identifiable {
    case calories
    case macro(Macronutrient)

    var id: String {
        switch self {
        case .calories: return "calories"
        case .macro(let m): return m.rawValue
        }
    }

    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .macro(let m): return m.displayName
        }
    }

    var color: Color {
        switch self {
        case .calories: return .blue
        case .macro(.protein): return .red
        case .macro(.carbohydrate): return .green
        case .macro(.fat): return .yellow
        }
    }

    var isEnergy: Bool {
        if case .calories = self { return true }
        return false
    }

    static var all: [HistoryMetric] {
        [.calories] + Macronutrient.allCases.map { .macro($0) }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationView {
            List(HistoryMetric.all) { metric in
                NavigationLink(destination: NutritionMetricHistoryView(metric: metric)) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(metric.color)
                            .frame(width: 12, height: 12)
                        Text(metric.displayName)
                    }
                }
            }
            .padding(.bottom, ContentView.tabBarClearance)
            .navigationTitle("History")
        }
    }
}

struct NutritionMetricHistoryView: View {
    let metric: HistoryMetric

    @EnvironmentObject var viewModel: NutritionViewModel
    @AppStorage("energyUnit") private var energyUnitRaw: String = EnergyUnit.calories.rawValue
    @State private var selectedRange: HistoryTimeRange = .week

    private var energyUnit: EnergyUnit {
        EnergyUnit(rawValue: energyUnitRaw) ?? .calories
    }

    private var points: [NutritionHistoryPoint] {
        viewModel.history(for: selectedRange)
    }

    /// Only buckets the user actually logged something in — excludes days/months
    /// before they started tracking, so the average isn't diluted by silence.
    private var loggedPoints: [NutritionHistoryPoint] {
        points.filter { $0.hasEntries }
    }

    private var unitSuffix: String {
        metric.isEnergy ? energyUnit.abbreviation : "g"
    }

    private var averageValue: Double {
        guard !loggedPoints.isEmpty else { return 0 }
        let total = loggedPoints.reduce(0.0) { $0 + displayValue(for: $1) }
        return total / Double(loggedPoints.count)
    }

    /// Week/month bars are daily totals; year bars are monthly totals — the
    /// label has to match what's actually being averaged, or it's misleading.
    private var averageLabel: String {
        selectedRange == .year ? "Monthly Average" : "Daily Average"
    }

    private var xAxisFormat: Date.FormatStyle {
        switch selectedRange {
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day()
        case .year: return .dateTime.month(.abbreviated)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Range", selection: $selectedRange) {
                    ForEach(HistoryTimeRange.allCases) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text(averageLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if loggedPoints.isEmpty {
                        Text("No data logged for this period yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(Int(averageValue.rounded())) \(unitSuffix)")
                            .font(.title2)
                            .bold()
                    }
                }

                Chart(points) { point in
                    BarMark(
                        x: .value("Date", point.periodStart),
                        y: .value(metric.displayName, displayValue(for: point))
                    )
                    .foregroundStyle(metric.color)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: xAxisFormat)
                    }
                }
                .frame(height: 220)
            }
            .padding()
            .padding(.bottom, ContentView.tabBarClearance)
        }
        .navigationTitle(metric.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayValue(for point: NutritionHistoryPoint) -> Double {
        let raw = point.value(for: metric)
        return metric.isEnergy ? energyUnit.convert(fromKilocalories: raw) : raw
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView().environmentObject(NutritionViewModel())
    }
}
