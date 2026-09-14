//
//  AdequacyStatus.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

enum AdequacyStatus {
    case low
    case onTrack
    case high

    var displayLabel: String {
        switch self {
        case .low: return "Below target"
        case .onTrack: return "On track"
        case .high: return "Above target"
        }
    }
}
