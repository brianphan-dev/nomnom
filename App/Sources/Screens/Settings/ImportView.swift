import SwiftUI
import UniformTypeIdentifiers
import NomNomShared
import NomNomCore
import NomNomDesignSystem

/// Historical nutrition importer supporting MyFitnessPal CSV rollups and Apple Health dietary logs.
public struct ImportView: View {
    private let store: NomNomAppStore
    private let onClose: () -> Void
    private let onCompleted: (ImportSummary) -> Void

    // MyFitnessPal CSV state
    @State private var showFileImporter: Bool = false
    @State private var loadedCSVText: String?
    @State private var loadedFileName: String?
    @State private var parsedResult: MyFitnessPalParseResult?
    @State private var duplicatePolicy: DuplicatePolicy = .skip
    @State private var isImportingMFP: Bool = false

    // Apple Health state
    @State private var healthLookbackDays: Int = 30
    @State private var isImportingHealth: Bool = false

    // Feedback & completion receipt
    @State private var errorTitle: String?
    @State private var errorMessage: String?
    @State private var completedSummary: ImportSummary?

    private static let detectedColumns: [String] = [
        "Date",
        "Meal",
        "Calories",
        "Protein",
        "Carbs",
        "Fat",
    ]

    public init(
        store: NomNomAppStore,
        onClose: @escaping () -> Void,
        onCompleted: @escaping (ImportSummary) -> Void
    ) {
        self.store = store
        self.onClose = onClose
        self.onCompleted = onCompleted
    }

    private var policyOptions: [NNSegmentOption<DuplicatePolicy>] {
        [
            NNSegmentOption(value: .skip, label: "Skip duplicates"),
            NNSegmentOption(value: .replaceDate, label: "Replace date"),
            NNSegmentOption(value: .keepBoth, label: "Keep both"),
        ]
    }

    private var policyExplanation: String {
        switch duplicatePolicy {
        case .skip:
            "Keep meals already in nomnom when dates and totals match."
        case .replaceDate:
            "Imported dates replace existing entries on those days."
        case .keepBoth:
            "Import every row from the CSV, even if it repeats."
        }
    }

    private var lookbackOptions: [NNSegmentOption<Int>] {
        [
            NNSegmentOption(value: 7, label: "7 days"),
            NNSegmentOption(value: 30, label: "30 days"),
            NNSegmentOption(value: 90, label: "90 days"),
        ]
    }

    public var body: some View {
        VStack(spacing: 0) {
            NNNavBar(
                title: "Import history",
                leading: {
                    NNIconButton(
                        icon: .close,
                        label: "Close",
                        variant: .filled,
                        size: 36,
                        action: onClose
                    )
                }
            )
            .padding(.top, NNSpacing.s2)

            if let summary = completedSummary {
                completionReceiptView(summary: summary)
            } else {
                mainImportScrollView
            }
        }
        .background(NNColor.bgApp.ignoresSafeArea())
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImportResult(result)
        }
    }

    // MARK: - Main Import Content

    private var mainImportScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NNSpacing.s5) {
                if let errorTitle, let errorMessage {
                    NNBanner(
                        tone: .info,
                        icon: .info,
                        title: errorTitle,
                        message: errorMessage
                    )
                }

                myFitnessPalSection
                appleHealthSection
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.top, NNSpacing.s4)
            .padding(.bottom, NNSpacing.s8)
        }
    }

    // MARK: - Source 1: MyFitnessPal CSV

    private var myFitnessPalSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s3) {
            Text("MyFitnessPal CSV")
                .nnOverlineStyle()
                .padding(.horizontal, 4)

            NNBanner(
                tone: .info,
                icon: .info,
                title: "MyFitnessPal exports meal totals",
                message: "MyFitnessPal exports meal totals per day rather than individual ingredients."
            )

            NNCard(padding: .md) {
                VStack(alignment: .leading, spacing: NNSpacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loadedFileName ?? "Nutrition-Summary.csv")
                            .nnTextStyle(.headline)
                            .foregroundStyle(NNColor.textPrimary)
                        Text("Choose an exported CSV file, or load a sample export to preview.")
                            .nnTextStyle(.footnote)
                            .foregroundStyle(NNColor.textSecondary)
                    }

                    HStack(spacing: NNSpacing.s2) {
                        NNButton(
                            "Choose MyFitnessPal CSV",
                            variant: .primary,
                            size: .md,
                            icon: .importHistory,
                            fullWidth: true
                        ) {
                            showFileImporter = true
                        }
                    }

                    NNButton(
                        "Try sample CSV",
                        variant: .secondary,
                        size: .sm,
                        fullWidth: true
                    ) {
                        loadSampleCSV()
                    }
                }
            }

            if let parsedResult {
                parsedCSVPreviewSection(parsedResult)
            }
        }
    }

    private func parsedCSVPreviewSection(_ result: MyFitnessPalParseResult) -> some View {
        let previewRows = Array(result.rows.prefix(4))
        let sortedDates = result.rows.map(\.localDate).sorted()
        let rangeText: String = if let first = sortedDates.first, let last = sortedDates.last, first != last {
            "\(result.rows.count) meals between \(formatShortDate(first)) and \(formatShortDate(last))."
        } else if let only = sortedDates.first {
            "\(result.rows.count) meals on \(formatShortDate(only))."
        } else {
            "No valid meal rows found."
        }

        return VStack(alignment: .leading, spacing: NNSpacing.s3) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Self.detectedColumns, id: \.self) { column in
                        NNBadge(column, tone: .positive, icon: .check)
                    }
                }
            }

            NNCard(padding: .md) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text("Date")
                            .frame(width: 56, alignment: .leading)
                        Text("Meal")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("kcal")
                            .frame(width: 48, alignment: .trailing)
                        Text("P")
                            .frame(width: 32, alignment: .trailing)
                        Text("C")
                            .frame(width: 32, alignment: .trailing)
                        Text("F")
                            .frame(width: 32, alignment: .trailing)
                    }
                    .nnOverlineStyle()
                    .padding(.bottom, 8)

                    ForEach(Array(previewRows.enumerated()), id: \.offset) { _, row in
                        Rectangle()
                            .fill(NNColor.borderHairline)
                            .frame(height: 1)

                        HStack(spacing: 6) {
                            Text(formatShortDate(row.localDate))
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textSecondary)
                                .frame(width: 56, alignment: .leading)
                                .lineLimit(1)

                            Text(row.mealType.displayName)
                                .font(NNFont.sans(size: 13, weight: .medium, relativeTo: .footnote))
                                .foregroundStyle(NNColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)

                            Text(NNFormatting.kcal(row.nutrition.caloriesKcal))
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textPrimary)
                                .frame(width: 48, alignment: .trailing)

                            Text("\(Int(row.nutrition.proteinG.rounded()))")
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textSecondary)
                                .frame(width: 32, alignment: .trailing)

                            Text("\(Int(row.nutrition.carbsG.rounded()))")
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textSecondary)
                                .frame(width: 32, alignment: .trailing)

                            Text("\(Int(row.nutrition.fatG.rounded()))")
                                .nnTextStyle(.numSm)
                                .foregroundStyle(NNColor.textSecondary)
                                .frame(width: 32, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            Text(rangeText)
                .nnTextStyle(.subhead)
                .foregroundStyle(NNColor.textSecondary)
                .padding(.horizontal, 4)

            if !result.warnings.isEmpty {
                NNBanner(
                    tone: .info,
                    icon: .info,
                    title: "\(result.warnings.count) row notes",
                    message: result.warnings.prefix(2).joined(separator: " ")
                )
            }

            VStack(alignment: .leading, spacing: NNSpacing.s2) {
                Text("If a meal is already here")
                    .nnOverlineStyle()
                    .padding(.horizontal, 4)

                NNSegmentedControl(
                    options: policyOptions,
                    selection: $duplicatePolicy,
                    size: .sm
                )

                Text(policyExplanation)
                    .nnTextStyle(.footnote)
                    .foregroundStyle(NNColor.textSecondary)
                    .padding(.horizontal, 4)
            }

            NNButton(
                "Import \(result.rows.count) \(result.rows.count == 1 ? "meal" : "meals")",
                variant: .accent,
                size: .lg,
                fullWidth: true,
                loading: isImportingMFP
            ) {
                Task {
                    await runMyFitnessPalImport()
                }
            }
            .disabled(result.rows.isEmpty)
        }
    }

    // MARK: - Source 2: Apple Health

    private var appleHealthSection: some View {
        VStack(alignment: .leading, spacing: NNSpacing.s3) {
            Text("Apple Health")
                .nnOverlineStyle()
                .padding(.horizontal, 4)

            NNCard(padding: .md) {
                VStack(alignment: .leading, spacing: NNSpacing.s4) {
                    HStack(spacing: NNSpacing.s3) {
                        NNIconView(.appleHealth, size: 18, weight: .regular, color: NNColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(NNColor.fill1, in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Read calories and macros from Health")
                                .nnTextStyle(.headline)
                                .foregroundStyle(NNColor.textPrimary)
                            Text("Entries already imported into nomnom are skipped automatically.")
                                .nnTextStyle(.footnote)
                                .foregroundStyle(NNColor.textSecondary)
                        }
                    }

                    NNSegmentedControl(
                        options: lookbackOptions,
                        selection: $healthLookbackDays,
                        size: .sm
                    )

                    NNButton(
                        isImportingHealth ? "Importing\u{2026}" : "Import from Apple Health",
                        variant: .secondary,
                        size: .md,
                        icon: .appleHealth,
                        fullWidth: true,
                        loading: isImportingHealth
                    ) {
                        Task {
                            await runHealthKitImport()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Completion Receipt

    private func completionReceiptView(summary: ImportSummary) -> some View {
        var detailParts: [String?] = [
            "\(summary.importedCount) \(summary.importedCount == 1 ? "meal" : "meals") imported",
        ]
        if summary.skippedCount > 0 {
            detailParts.append("\(summary.skippedCount) skipped")
        }
        if summary.replacedCount > 0 {
            detailParts.append("\(summary.replacedCount) replaced")
        }

        return VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: NNSpacing.s3) {
                NNIconView(.checkCircle, size: 44, weight: .fill, color: NNColor.positive)

                Text("Import finished")
                    .nnTextStyle(.largeTitle)
                    .foregroundStyle(NNColor.textPrimary)

                Text(NNFormatting.metadataLine(detailParts))
                    .nnTextStyle(.callout)
                    .foregroundStyle(NNColor.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Source: \(summary.source)")
                    .nnTextStyle(.footnote)
                    .foregroundStyle(NNColor.textTertiary)
            }
            .padding(.horizontal, NNSpacing.screenMargin)

            Spacer(minLength: 0)

            NNButton("Back to Today", variant: .primary, size: .lg, fullWidth: true) {
                onCompleted(summary)
            }
            .padding(.horizontal, NNSpacing.screenMargin)
            .padding(.bottom, NNSpacing.s6)
        }
    }

    // MARK: - File Loading & Importers

    private func handleFileImportResult(_ result: Result<[URL], any Error>) {
        errorTitle = nil
        errorMessage = nil

        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let rawData = try Data(contentsOf: url)
                let text = String(data: rawData, encoding: .utf8)
                    ?? String(data: rawData, encoding: .isoLatin1)
                guard let text else {
                    errorTitle = "Couldn't read file"
                    errorMessage = "The selected file could not be decoded as UTF-8 text."
                    return
                }
                try parseCSV(text, filename: url.lastPathComponent)
            } catch {
                errorTitle = "Couldn't open CSV"
                errorMessage = error.localizedDescription
            }

        case let .failure(error):
            errorTitle = "Couldn't open file"
            errorMessage = error.localizedDescription
        }
    }

    private func loadSampleCSV() {
        errorTitle = nil
        errorMessage = nil
        let sample = Self.makeSampleMyFitnessPalCSV(anchorDate: store.selectedDate)
        do {
            try parseCSV(sample, filename: "Sample-Nutrition-Summary.csv")
        } catch {
            errorTitle = "Sample CSV error"
            errorMessage = error.localizedDescription
        }
    }

    private func parseCSV(_ csv: String, filename: String) throws {
        do {
            let parsed = try MyFitnessPalParser.parse(csv: csv)
            loadedCSVText = csv
            loadedFileName = filename
            parsedResult = parsed
        } catch let importError as MyFitnessPalImportError {
            loadedCSVText = nil
            parsedResult = nil
            errorTitle = "Invalid MyFitnessPal CSV"
            switch importError {
            case .emptyCSV:
                errorMessage = "This CSV file is empty."
            case let .missingRequiredColumns(missing):
                errorMessage = "Missing required columns: \(missing.joined(separator: ", "))."
            case .csvSyntaxError:
                errorMessage = "The CSV file has malformed quotes or commas."
            }
        }
    }

    private func runMyFitnessPalImport() async {
        guard let csv = loadedCSVText, !isImportingMFP else { return }
        isImportingMFP = true
        errorTitle = nil
        errorMessage = nil
        defer { isImportingMFP = false }

        do {
            let summary = try await store.importMyFitnessPalCSV(csv, policy: duplicatePolicy)
            Task {
                if store.isSignedIn && !store.isOffline {
                    _ = try? await store.syncNow()
                }
            }
            completedSummary = summary
        } catch {
            errorTitle = "Import failed"
            errorMessage = error.localizedDescription
        }
    }

    private func runHealthKitImport() async {
        guard !isImportingHealth else { return }
        isImportingHealth = true
        errorTitle = nil
        errorMessage = nil
        defer { isImportingHealth = false }

        do {
            let summary = try await store.importFromHealthKit(days: healthLookbackDays)
            Task {
                if store.isSignedIn && !store.isOffline {
                    _ = try? await store.syncNow()
                }
            }
            completedSummary = summary
        } catch {
            errorTitle = "Apple Health import unavailable"
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Formatting & Sample CSV

    private func formatShortDate(_ localDate: String) -> String {
        let parts = localDate.split(separator: "-")
        guard parts.count == 3,
              let monthNum = Int(parts[1]),
              let dayNum = Int(parts[2]),
              (1...12).contains(monthNum)
        else {
            return localDate
        }
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return "\(dayNum) \(months[monthNum - 1])"
    }

    private static func makeSampleMyFitnessPalCSV(anchorDate: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: anchorDate) ?? anchorDate
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: anchorDate) ?? anchorDate

        let d1 = NomNomAppStore.localDateString(for: yesterday)
        let d2 = NomNomAppStore.localDateString(for: twoDaysAgo)

        return """
        Date,Meal,Calories,Fat (g),Carbohydrates (g),Protein (g),Fiber (g),Sodium (mg),Note
        \(d1),Breakfast,412,14,48,22,7,320,Overnight oats and berries
        \(d1),Lunch,688,28,62,41,9,780,Salmon rice bowl
        \(d1),Dinner,734,27,70,46,8,690,Grilled chicken thigh plate
        \(d1),Snacks,190,8,24,6,3,110,Almonds and flat white
        \(d2),Breakfast,385,12,44,24,6,290,Greek yogurt and toast
        \(d2),Lunch,640,22,68,39,8,640,Turkey avocado wrap
        """
    }
}
