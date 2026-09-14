//
//  MacronutrientEducationContent.swift
//  MacroEasy
//
//  Created by Eden Hallett on 14/9/2026.
//

import Foundation

struct MacronutrientEducationContent {
    let macro: Macronutrient
    let whyYouNeedIt: String
    let goalSpecificGuidance: [NutritionGoal: String]
    let foodSuggestions: [String]

    static let all: [Macronutrient: MacronutrientEducationContent] = [
        .protein: MacronutrientEducationContent(
            macro: .protein,
            whyYouNeedIt: "Protein helps repair and build the tissues in your body, from muscles to skin, and helps you feel full after eating.",
            goalSpecificGuidance: [
                .loseWeight: "Higher protein intake helps you stay full for longer, which can make it easier to eat less overall.",
                .maintain: "Steady protein intake throughout the day supports general repair and recovery.",
                .buildMuscle: "Extra protein gives your muscles the raw material they need to recover and grow after training."
            ],
            foodSuggestions: ["Chicken breast", "Greek yoghurt", "Lentils", "Eggs", "Tofu"]
        ),
        .carbohydrate: MacronutrientEducationContent(
            macro: .carbohydrate,
            whyYouNeedIt: "Carbohydrates are your body's main energy source, fuelling your brain and muscles throughout the day.",
            goalSpecificGuidance: [
                .loseWeight: "Choosing slower-digesting carbs (like whole grains) can help you feel fuller for longer on fewer calories.",
                .maintain: "Consistent carb intake helps keep your energy levels steady across the day.",
                .buildMuscle: "Carbs fuel your workouts and help replenish energy stores afterward, supporting recovery."
            ],
            foodSuggestions: ["Brown rice", "Oats", "Sweet potato", "Wholegrain bread", "Fruit"]
        ),
        .fat: MacronutrientEducationContent(
            macro: .fat,
            whyYouNeedIt: "Fat supports hormone production and helps your body absorb certain vitamins — it's essential, not something to eliminate.",
            goalSpecificGuidance: [
                .loseWeight: "Fat is more calorie-dense than protein or carbs, so smaller portions still go a long way.",
                .maintain: "A balanced fat intake supports long-term hormonal and cellular health.",
                .buildMuscle: "Healthy fats support hormone production, including hormones involved in muscle growth."
            ],
            foodSuggestions: ["Avocado", "Olive oil", "Nuts", "Salmon", "Chia seeds"]
        )
    ]
}
