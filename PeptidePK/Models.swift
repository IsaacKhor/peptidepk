//
//  Models.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import Foundation
import SwiftData
import SwiftUI

enum GLPDrug: String, CaseIterable, Codable, Identifiable {
    case semaglutide
    case tirzepatide
    case retatrutide

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .semaglutide:
            "Semaglutide"
        case .tirzepatide:
            "Tirzepatide"
        case .retatrutide:
            "Retatrutide"
        }
    }

    var shortName: String {
        switch self {
        case .semaglutide:
            "Sema"
        case .tirzepatide:
            "Tirz"
        case .retatrutide:
            "Reta"
        }
    }

    var color: Color {
        switch self {
        case .semaglutide:
            .teal
        case .tirzepatide:
            .indigo
        case .retatrutide:
            .pink
        }
    }

    var defaultDoseMilligrams: Double {
        switch self {
        case .semaglutide:
            0.25
        case .tirzepatide:
            2.5
        case .retatrutide:
            2.0
        }
    }

    var defaultHalfLifeHours: Double {
        switch self {
        case .semaglutide:
            168.0
        case .tirzepatide:
            120.0
        case .retatrutide:
            144.0
        }
    }

    var defaultAbsorptionHalfLifeHours: Double {
        switch self {
        case .semaglutide:
            24.0
        case .tirzepatide:
            24.0
        case .retatrutide:
            18.0
        }
    }

    var defaultBioavailability: Double {
        switch self {
        case .semaglutide:
            0.89
        case .tirzepatide:
            0.80
        case .retatrutide:
            0.80
        }
    }

    var defaultVolumeOfDistributionLitersPerKilogram: Double {
        switch self {
        case .semaglutide:
            0.147
        case .tirzepatide:
            0.121
        case .retatrutide:
            0.125
        }
    }
}

enum PKDisplayMode: String, CaseIterable, Codable, Identifiable {
    case wholeBodyAmount
    case relativeAmount
    case serumConcentration

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .relativeAmount:
            "Relative"
        case .serumConcentration:
            "Serum"
        case .wholeBodyAmount:
            "Total"
        }
    }

    var axisTitle: String {
        switch self {
        case .relativeAmount:
            "Active amount (mcg/kg)"
        case .serumConcentration:
            "Serum concentration (ng/mL)"
        case .wholeBodyAmount:
            "Whole-body amount (mg)"
        }
    }

    var unitSymbol: String {
        switch self {
        case .relativeAmount:
            "mcg/kg"
        case .serumConcentration:
            "ng/mL"
        case .wholeBodyAmount:
            "mg"
        }
    }
}

struct DrugPKParameters {
    var halfLifeHours: Double
    var absorptionHalfLifeHours: Double
    var bioavailability: Double
    var volumeOfDistributionLitersPerKilogram: Double
}

extension GLPDrug {
    // Published PK defaults used as fixed model constants.
    var publishedPKParameters: DrugPKParameters {
        DrugPKParameters(
            halfLifeHours: defaultHalfLifeHours,
            absorptionHalfLifeHours: defaultAbsorptionHalfLifeHours,
            bioavailability: defaultBioavailability,
            volumeOfDistributionLitersPerKilogram: defaultVolumeOfDistributionLitersPerKilogram
        )
    }
}

@Model
final class Injection {
    var timestamp: Date = Date()
    var drugRawValue: String = GLPDrug.semaglutide.rawValue
    var doseMilligrams: Double = GLPDrug.semaglutide.defaultDoseMilligrams
    var createdAt: Date = Date()

    init(timestamp: Date = Date(), drug: GLPDrug = .semaglutide, doseMilligrams: Double = GLPDrug.semaglutide.defaultDoseMilligrams) {
        self.timestamp = timestamp
        self.drugRawValue = drug.rawValue
        self.doseMilligrams = doseMilligrams
        self.createdAt = Date()
    }
}

extension Injection {
    var drug: GLPDrug {
        get { GLPDrug(rawValue: drugRawValue) ?? .semaglutide }
        set { drugRawValue = newValue.rawValue }
    }
}

@Model
final class PKSettings {
    var createdAt: Date = Date()
    var displayModeRawValue: String = PKDisplayMode.wholeBodyAmount.rawValue
    var bodyWeightKilograms: Double = 70.0
    var graphPastDays: Double = 35.0
    var graphFutureDays: Double = 14.0

    init() { }
}

extension PKSettings {
    var displayMode: PKDisplayMode {
        get { PKDisplayMode(rawValue: displayModeRawValue) ?? .relativeAmount }
        set { displayModeRawValue = newValue.rawValue }
    }
}
