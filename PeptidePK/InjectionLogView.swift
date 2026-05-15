//
//  InjectionLogView.swift
//  PeptidePK
//
//  Created by Isaac Khor on 2026.05.15.
//

import SwiftData
import SwiftUI

struct InjectionDraft {
    var timestamp: Date = Date()
    var drug: GLPDrug = .semaglutide
    var doseMilligrams: Double = GLPDrug.semaglutide.defaultDoseMilligrams
}

struct InjectionLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Injection.timestamp, order: .reverse) private var injections: [Injection]

    @State private var draft = InjectionDraft()
    @State private var isAddingInjection = false
    @State private var editingInjection: Injection?

    var body: some View {
        NavigationStack {
            List {
                if injections.isEmpty {
                    ContentUnavailableView(
                        "No Injections",
                        systemImage: "syringe",
                        description: Text("Tap plus to add your first injection.")
                    )
                } else {
                    ForEach(injections) { injection in
                        Button {
                            editingInjection = injection
                        } label: {
                            InjectionRow(injection: injection)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteInjections)
                }
            }
            .navigationTitle("Injection Log")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        prepareDraftFromPreviousInjection()
                        isAddingInjection = true
                    } label: {
                        Label("Add Injection", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingInjection) {
                AddInjectionView(draft: $draft) {
                    addInjection()
                }
            }
            .sheet(item: $editingInjection) { injection in
                EditInjectionView(injection: injection)
            }
        }
    }

    private func prepareDraftFromPreviousInjection() {
        if let previousInjection = injections.first {
            draft = InjectionDraft(
                timestamp: Date(),
                drug: previousInjection.drug,
                doseMilligrams: previousInjection.doseMilligrams
            )
        } else {
            draft = InjectionDraft()
        }
    }

    private func addInjection() {
        let injection = Injection(
            timestamp: draft.timestamp,
            drug: draft.drug,
            doseMilligrams: draft.doseMilligrams
        )
        modelContext.insert(injection)
        isAddingInjection = false
    }

    private func deleteInjections(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(injections[index])
            }
        }
    }
}

private struct InjectionRow: View {
    var injection: Injection

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(injection.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.body)

                Text(injection.drug.displayName)
                    .font(.subheadline)
                    .foregroundStyle(injection.drug.color)
            }

            Spacer()

            Text("\(injection.doseMilligrams.formatted(.number.precision(.fractionLength(0...3)))) mg")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct AddInjectionView: View {
    @Binding var draft: InjectionDraft
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            InjectionFields(
                timestamp: $draft.timestamp,
                drug: $draft.drug,
                doseMilligrams: $draft.doseMilligrams
            )
            .navigationTitle("Add Injection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(draft.doseMilligrams <= 0)
                }
            }
        }
    }
}

private struct EditInjectionView: View {
    @Bindable var injection: Injection
    @Environment(\.dismiss) private var dismiss

    private var drug: Binding<GLPDrug> {
        Binding {
            injection.drug
        } set: { newValue in
            injection.drug = newValue
        }
    }

    var body: some View {
        NavigationStack {
            InjectionFields(
                timestamp: $injection.timestamp,
                drug: drug,
                doseMilligrams: $injection.doseMilligrams
            )
            .navigationTitle("Edit Injection")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(injection.doseMilligrams <= 0)
                }
            }
        }
    }
}

private struct InjectionFields: View {
    @Binding var timestamp: Date
    @Binding var drug: GLPDrug
    @Binding var doseMilligrams: Double

    var body: some View {
        Form {
            Section {
                DatePicker("Time", selection: $timestamp)

                Picker("Drug", selection: $drug) {
                    ForEach(GLPDrug.allCases) { drug in
                        Text(drug.displayName)
                            .tag(drug)
                    }
                }

                TextField(
                    "Dosage",
                    value: $doseMilligrams,
                    format: .number.precision(.fractionLength(0...3))
                )
                .keyboardType(.decimalPad)
            }

            Section {
                LabeledContent("Dose", value: "\(doseMilligrams.formatted(.number.precision(.fractionLength(0...3)))) mg")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PeptidePKApp.previewModelContainer)
}
