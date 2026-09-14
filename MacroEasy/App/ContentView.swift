//
//  ContentView.swift
//  MacroEasy
//
//  Created by Eden Hallett on 11/9/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NutritionViewModel()
    @State private var selectedTab: Tab = .today
    @State private var showLogMeal = false
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    enum Tab {
        case today, targets, settings
    }

    static let tabBarClearance: CGFloat = 100

    private var preferredColorScheme: ColorScheme? {
        (AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .today:
                    DashboardView()
                case .targets:
                    TargetsView()
                case .settings:
                    SettingsView()
                }
            }
            .environmentObject(viewModel)

            customTabBar
        }
        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: $showLogMeal, onDismiss: {
            viewModel.refreshDashboard()
        }) {
            LogMealView()
                .environmentObject(viewModel)
        }
    }

    private var customTabBar: some View {
        ZStack {
            HStack {
                HStack(spacing: 28) {
                    tabButton(tab: .today, systemImage: "house.fill", label: "Today")
                    tabButton(tab: .targets, systemImage: "target", label: "Targets")
                }

                Spacer()

                HStack(spacing: 28) {
                    tabButton(tab: .settings, systemImage: "gearshape.fill", label: "Settings")
                }
            }
            .padding(.horizontal, 40)

            logButton
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(tab: Tab, systemImage: String, label: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
        }
    }

    private var logButton: some View {
        Button {
            showLogMeal = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .offset(y: -18)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
