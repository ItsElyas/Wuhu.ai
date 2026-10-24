import SwiftUI
import SwiftData

struct BodyMapView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Query private var bodyRecords: [BodyPartStatusRecord]
    @Query(sort: \WorkoutRecord.startDate, order: .reverse) private var workouts: [WorkoutRecord]
    @State private var viewModel = BodyMapViewModel()
    @State private var prefer3D = false
    @State private var detailPart: BodyPart?

    private var wearByPart: [BodyPart: WearLevel] {
        app.wearTearResult?.wear ?? [:]
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Range", selection: $viewModel.range) {
                ForEach(BodyMapViewModel.BodyMapRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            legend

            ZStack {
                if prefer3D {
                    BodyMap3DView(
                        statusForPart: { viewModel.effectiveStatus(for: $0, in: Array(bodyRecords), wear: wearByPart) },
                        wearLevelForPart: viewModel.range == .daily ? { viewModel.wearLevel(for: $0, wear: wearByPart) } : nil,
                        onSelect: { detailPart = $0 }
                    )
                    .frame(maxHeight: 420)
                } else {
                    BodyMap2DView(
                        showFront: viewModel.showFront,
                        statusForPart: { viewModel.effectiveStatus(for: $0, in: Array(bodyRecords), wear: wearByPart) },
                        wearLevelForPart: viewModel.range == .daily ? { viewModel.wearLevel(for: $0, wear: wearByPart) } : nil,
                        weeklyLoadForPart: { viewModel.weeklyLoad(for: $0, workouts: Array(workouts)) },
                        heatMode: viewModel.range == .weekly,
                        onSelect: { detailPart = $0 }
                    )
                    .padding(.horizontal, 24)
                }
            }

            HStack {
                Button {
                    viewModel.showFront.toggle()
                } label: {
                    Label(viewModel.showFront ? "Show back" : "Show front", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)

                Button {
                    prefer3D.toggle()
                } label: {
                    Label(prefer3D ? "2D map" : "3D map", systemImage: prefer3D ? "square" : "cube")
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.showList = true
                } label: {
                    Label("List", systemImage: "list.bullet")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Text("Tracking aid only — not medical advice. Tap a red (injured) part for recovery tips.")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Body Map")
        .onAppear {
            app.refreshWear(modelContext: modelContext, bodyRecords: Array(bodyRecords))
        }
        .onChange(of: bodyRecords.count) { _, _ in
            app.refreshWear(modelContext: modelContext, bodyRecords: Array(bodyRecords))
        }
        .onChange(of: workouts.count) { _, _ in
            app.refreshWear(modelContext: modelContext, bodyRecords: Array(bodyRecords))
        }
        .sheet(item: $detailPart) { part in
            PartDetailSheet(
                part: part,
                record: bodyRecords.first { $0.part == part },
                recentWorkouts: workouts.filter {
                    $0.musclesWorked.contains(part)
                        || WorkoutLoadMapper.parts(forWorkoutType: $0.type).contains(part)
                },
                onSave: { status, severity, note in
                    var records = Array(bodyRecords)
                    viewModel.updateStatus(
                        part: part,
                        status: status,
                        severity: severity,
                        note: note,
                        records: &records,
                        context: modelContext
                    )
                    app.refreshWear(modelContext: modelContext, bodyRecords: records)
                }
            )
        }
        .sheet(isPresented: $viewModel.showList) {
            NavigationStack {
                List {
                    ForEach(BodyPart.allCases) { part in
                        let status = viewModel.effectiveStatus(for: part, in: Array(bodyRecords), wear: wearByPart)
                        Button {
                            viewModel.showList = false
                            detailPart = part
                        } label: {
                            HStack {
                                Image(systemName: part.symbolName)
                                Text(part.displayName)
                                Spacer()
                                statusBadge(status.0)
                            }
                        }
                        .accessibilityHint(status.0 == .injured ? "Opens healing recommendations" : "Opens status details")
                    }
                }
                .navigationTitle("All body parts")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { viewModel.showList = false }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: AppColors.injuredRed, icon: "cross.case.fill", text: "Injured")
            legendItem(color: AppColors.soreYellow, icon: "exclamationmark.triangle.fill", text: "Sore / worked")
            legendItem(color: AppColors.healthyNeutral, icon: "circle", text: "Healthy")
        }
        .font(AppTypography.caption)
        .padding(.horizontal)
    }

    private func legendItem(color: Color, icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text)
        }
        .accessibilityElement(children: .combine)
    }

    private func statusBadge(_ status: BodyStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: status == .injured ? "cross.case.fill" : (status == .healthy ? "circle" : "exclamationmark.triangle.fill"))
            Text(status.rawValue.capitalized)
                .font(AppTypography.caption)
        }
        .foregroundStyle(AppColors.bodyStatusColor(status: status, intensity: 1))
    }
}

#Preview {
    NavigationStack {
        BodyMapView()
    }
    .modelContainer(for: [BodyPartStatusRecord.self, WorkoutRecord.self], inMemory: true)
}
