//
//  AppSettings.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//


import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum EnergyUnit: String, CaseIterable, Identifiable {
    case calories
    case kilojoules

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calories: return "Calories"
        case .kilojoules: return "Kilojoules"
        }
    }

    var abbreviation: String {
        switch self {
        case .calories: return "cal"
        case .kilojoules: return "kJ"
        }
    }

    func convert(fromKilocalories kcal: Double) -> Double {
        switch self {
        case .calories: return kcal
        case .kilojoules: return kcal * 4.184
        }
    }
    
    func toKilocalories(_ value: Double) -> Double {
        switch self {
        case .calories: return value
        case .kilojoules: return value / 4.184
        }
    }
  
    func format(fromKilocalories kcal: Double) -> String {
        "\(Int(convert(fromKilocalories: kcal).rounded())) \(abbreviation)"
    }
}
