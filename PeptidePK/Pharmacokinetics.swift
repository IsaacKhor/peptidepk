//
//  Pharmacokinetics.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import Foundation

struct PKSample: Identifiable {
    var date: Date
    var drug: GLPDrug
    var value: Double

    var id: String {
        "\(drug.rawValue)-\(date.timeIntervalSinceReferenceDate)"
    }
}

struct CurrentDrugLevel: Identifiable {
    var drug: GLPDrug
    var value: Double

    var id: String { drug.rawValue }
}

enum Pharmacokinetics {
    static func samples(
        from injections: [Injection],
        settings: PKSettings,
        now: Date = Date()
    ) -> [PKSample] {
        let activeDrugs = drugsWithInjections(injections)
        guard !activeDrugs.isEmpty else { return [] }

        let startDate = now.addingTimeInterval(-settings.graphPastDays * secondsPerDay)
        let endDate = now.addingTimeInterval(settings.graphFutureDays * secondsPerDay)
        let totalHours = max(1.0, endDate.timeIntervalSince(startDate) / secondsPerHour)
        let stepHours = min(12.0, max(2.0, totalHours / 220.0))

        var samples: [PKSample] = []
        var sampleDate = startDate

        while sampleDate <= endDate {
            for drug in activeDrugs {
                let value = displayValue(for: drug, at: sampleDate, injections: injections, settings: settings)
                samples.append(PKSample(date: sampleDate, drug: drug, value: value))
            }

            sampleDate = sampleDate.addingTimeInterval(stepHours * secondsPerHour)
        }

        return samples
    }

    static func currentLevels(
        from injections: [Injection],
        settings: PKSettings,
        now: Date = Date()
    ) -> [CurrentDrugLevel] {
        drugsWithInjections(injections)
            .map { drug in
                CurrentDrugLevel(
                    drug: drug,
                    value: displayValue(for: drug, at: now, injections: injections, settings: settings)
                )
            }
            .filter { $0.value > 0.0001 }
    }

    static func displayValue(
        for drug: GLPDrug,
        at date: Date,
        injections: [Injection],
        settings: PKSettings
    ) -> Double {
        let activeMilligrams = injections
            .filter { $0.drug == drug }
            .reduce(0.0) { total, injection in
                total + activeAmountMilligrams(for: injection, at: date, settings: settings)
            }

        let bodyWeight = max(1.0, settings.bodyWeightKilograms)

        switch settings.displayMode {
        case .relativeAmount:
            return activeMilligrams * 1_000.0 / bodyWeight
        case .serumConcentration:
            let parameters = drug.publishedPKParameters
            let volumeLiters = max(0.1, parameters.volumeOfDistributionLitersPerKilogram * bodyWeight)
            return activeMilligrams / volumeLiters * 1_000.0
        case .wholeBodyAmount:
            return activeMilligrams
        }
    }

    private static func activeAmountMilligrams(
        for injection: Injection,
        at date: Date,
        settings: PKSettings
    ) -> Double {
        let elapsedHours = date.timeIntervalSince(injection.timestamp) / secondsPerHour
        guard elapsedHours >= 0 else { return 0 }

        let parameters = injection.drug.publishedPKParameters
        let bioavailableDose = max(0, injection.doseMilligrams) * clamped(parameters.bioavailability, lowerBound: 0, upperBound: 1)
        let eliminationRate = log(2.0) / max(0.1, parameters.halfLifeHours)
        let absorptionRate = log(2.0) / max(0.1, parameters.absorptionHalfLifeHours)

        if abs(absorptionRate - eliminationRate) < 0.00001 {
            return bioavailableDose * absorptionRate * elapsedHours * exp(-eliminationRate * elapsedHours)
        }

        let amount = bioavailableDose * absorptionRate / (absorptionRate - eliminationRate)
            * (exp(-eliminationRate * elapsedHours) - exp(-absorptionRate * elapsedHours))

        return max(0, amount)
    }

    private static func drugsWithInjections(_ injections: [Injection]) -> [GLPDrug] {
        GLPDrug.allCases.filter { drug in
            injections.contains { $0.drug == drug }
        }
    }

    private static func clamped(_ value: Double, lowerBound: Double, upperBound: Double) -> Double {
        min(max(value, lowerBound), upperBound)
    }

    private static let secondsPerHour = 3_600.0
    private static let secondsPerDay = 86_400.0
}
