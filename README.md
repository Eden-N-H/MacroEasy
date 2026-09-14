# MacroEasy

*40005 Advanced iOS Development — Assessment 2, Project 1: Domain Solution MVP (Building a Human-Centred iOS Business Application)*

An iOS app designed to provide a quick and accessible way for low-health-literacy users to gain meaningful insight into their diet and receive tailored advice to achieve their fitness goals.

## Requirements

- iOS 17+

## Features

- **Log Meals** — Allows users to manually log meals by entering calories, with the option to include macronutrients. Meals can be saved for future re-logging.
- **Dashboard** — Includes calorie/kilojoule and macronutrient (protein, carbs, fat) progress rings, along with a list of meals logged today. If more than 3 days of historical data has been logged, tailored dietary insights are also provided.
- **Macro Definitions/Information** — Selecting a macronutrient progress ring opens a detail view showing a simple overview of that macronutrient, its characteristics, associated foods, and a target insight based on the user's current macro intake.
- **Targets** — Allows users to select a goal and a target calorie/kilojoule intake. Macro targets are generated automatically based on the user's goal and target calories/kilojoules.
- **History** — Allows users to view historical calorie/kilojoule and macronutrient trends across the past week, month, and year.
- **Settings** — Allows users to switch between light/dark mode and calories/kilojoules.

## Setup

Open `MacroEasy.xcodeproj` in Xcode (targets iOS 17+) and run on a simulator or device. On first launch, go to the **Targets** tab and set a goal before checking the Dashboard, as progress won't display until targets have been configured.

## AI Acknowledgement

I hereby acknowledge that AI was used to assist in writing the code to develop this application. Architecture and domain modelling were driven directly by me.

## Testing

8 unit tests are included, covering the 5 core use cases. It should be noted that `GenerateDietaryInsightUseCase` requires at least 3 days of logged data. To accommodate this, mock test data is generated through `MockNutritionRepository.swift`.
