//
//  SettingsView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("energyUnit") private var energyUnitRaw: String = EnergyUnit.calories.rawValue

    private var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .system },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    private var energyUnit: Binding<EnergyUnit> {
        Binding(
            get: { EnergyUnit(rawValue: energyUnitRaw) ?? .calories },
            set: { energyUnitRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Picker("Energy Unit", selection: energyUnit) {
                        ForEach(EnergyUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Units")
                } footer: {
                    Text("Changes how calories are displayed and entered around the app. Data is always stored in calories (kcal) for consistency.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
