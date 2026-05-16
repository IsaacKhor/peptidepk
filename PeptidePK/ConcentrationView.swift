//
//  ConcentrationView.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import Charts
import SwiftData
import SwiftUI

struct ConcentrationView: View {
    var settings: PKSettings?

    @Query(sort: \Injection.timestamp, order: .forward) private var injections: [Injection]

    var body: some View {
        NavigationStack {
            Group {
                if let settings {
                    if injections.isEmpty {
                        ContentUnavailableView(
                            "No Injections",
                            systemImage: "syringe",
                            description: Text("Add an injection in the Log tab.")
                        )
                    } else {
                        TimelineView(.periodic(from: .now, by: 1_800)) { timeline in
                            levelsContent(settings: settings, now: timeline.date)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Levels")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func levelsContent(settings: PKSettings, now: Date) -> some View {
        let samples = Pharmacokinetics.samples(from: injections, settings: settings, now: now)
        let currentLevels = Pharmacokinetics.currentLevels(from: injections, settings: settings, now: now)
        let bridgeSamples = currentLevels.map {
            PKSample(date: now, drug: $0.drug, value: $0.value)
        }
        let pastSamples = (samples.filter { $0.date <= now } + bridgeSamples)
            .sorted { $0.date < $1.date }
        let futureSamples = (bridgeSamples + samples.filter { $0.date > now })
            .sorted { $0.date < $1.date }

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Chart {
                    ForEach(pastSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value(settings.displayMode.axisTitle, sample.value),
                            series: .value("Series", "\(sample.drug.rawValue)-past")
                        )
                        .foregroundStyle(by: .value("Drug", sample.drug.displayName))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }

                    ForEach(futureSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value(settings.displayMode.axisTitle, sample.value),
                            series: .value("Series", "\(sample.drug.rawValue)-future")
                        )
                        .foregroundStyle(by: .value("Drug", sample.drug.displayName))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [4, 6]))
                    }

                    RuleMark(x: .value("Now", now))
                        .foregroundStyle(.secondary)
                        .lineStyle(.init(lineWidth: 1, dash: [5, 5]))
                }
                .chartForegroundStyleScale(drugColorScale)
                .chartYAxisLabel(settings.displayMode.axisTitle)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(minHeight: 320)
                .padding(.horizontal)
                .padding(.top, 8)

                currentLevelList(currentLevels, settings: settings)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func currentLevelList(_ levels: [CurrentDrugLevel], settings: PKSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Estimate")
                .font(.headline)

            if levels.isEmpty {
                Text("No active drug estimated.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(levels) { level in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(level.drug.color)
                            .frame(width: 10, height: 10)

                        Text(level.drug.displayName)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Text(formattedLevel(level.value, settings: settings))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func formattedLevel(_ value: Double, settings: PKSettings) -> String {
        let formatted = value.formatted(.number.precision(.fractionLength(0...2)))
        return "\(formatted) \(settings.displayMode.unitSymbol)"
    }

    private var drugColorScale: KeyValuePairs<String, Color> {
        [
            GLPDrug.semaglutide.displayName: GLPDrug.semaglutide.color,
            GLPDrug.tirzepatide.displayName: GLPDrug.tirzepatide.color,
            GLPDrug.retatrutide.displayName: GLPDrug.retatrutide.color
        ]
    }
}

#Preview {
    ContentView()
        .modelContainer(PeptidePKApp.previewModelContainer)
}
