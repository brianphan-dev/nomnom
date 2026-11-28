import Foundation
import SwiftUI
import NomNomCore
import NomNomDesignSystem
import NomNomShared

public struct RootView: View {
    public let store: NomNomAppStore

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var activeFullScreenRoute: FullScreenRoute?
    @State private var activeSheetRoute: SheetRoute?
    @State private var pendingFullScreenRoute: FullScreenRoute?
    @State private var pendingSheetRoute: SheetRoute?

    @State private var selectedMealId: UUID?
    @State private var hasAppliedLaunchCameraPreference = false

    @State private var activeToast: ToastNotice?
    @State private var toastDismissTask: Task<Void, Never>?

    public init(store: NomNomAppStore) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            let layoutClass = NNLayoutClass.resolve(
                size: proxy.size,
                horizontalSizeClass: horizontalSizeClass
            )

            Group {
                if store.isSignedIn {
                    signedInContent(layoutClass: layoutClass)
                } else {
                    SignInView(store: store)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(NNColor.bgApp.ignoresSafeArea())
            .environment(\.nnLayoutClass, layoutClass)
            .onChange(of: store.isSignedIn, initial: true) { _, isSignedIn in
                if isSignedIn {
                    applyLaunchCameraPreferenceIfNeeded(layoutClass: layoutClass)
                } else {
                    resetSessionPresentationState()
                }
            }
            .onChange(of: layoutClass.isDualPane) { _, isDualPane in
                if isDualPane, case .mealDetail = activeSheetRoute {
                    activeSheetRoute = nil
                }
            }
            .onChange(of: store.selectedLocalDate) { _, _ in
                pruneSelectedMealIfMissing()
            }
            .onChange(of: store.todayMeals.map(\.id)) { _, _ in
                pruneSelectedMealIfMissing()
            }
        }
    }

    // MARK: - Signed-In Shell

    @ViewBuilder
    private func signedInContent(layoutClass: NNLayoutClass) -> some View {
        ZStack(alignment: .top) {
            if layoutClass.isDualPane {
                NNDualPaneContainer {
                    todayPane(layoutClass: layoutClass)
                } right: {
                    if let selectedMealId,
                       let meal = store.todayMeals.first(where: { $0.id == selectedMealId })
                    {
                        MealDetailView(
                            store: store,
                            meal: meal,
                            embedded: true,
                            showCloseButton: true,
                            onClose: {
                                withAnimation(reduceMotion ? nil : NNMotion.easeStandard) {
                                    self.selectedMealId = nil
                                }
                            },
                            onDeleted: {
                                handleDeletedMeal()
                            }
                        )
                        .id(meal.id)
                    } else {
                        WeekTrendPane(store: store)
                    }
                }
            } else {
                todayPane(layoutClass: layoutClass)
            }

            if let toast = activeToast {
                NNBanner(
                    tone: toast.tone,
                    icon: toast.icon,
                    title: toast.title,
                    message: toast.message
                )
                .background(
                    NNColor.surfaceCard,
                    in: RoundedRectangle(cornerRadius: NNRadius.banner, style: .continuous)
                )
                .nnShadow(.float)
                .frame(maxWidth: 440)
                .padding(.horizontal, NNSpacing.screenMargin)
                .padding(.top, NNSpacing.s3)
                .onTapGesture {
                    dismissToast()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .fullScreenCover(item: $activeFullScreenRoute, onDismiss: drainPendingPresentations) { route in
            fullScreenDestination(for: route, layoutClass: layoutClass)
                .environment(\.nnLayoutClass, layoutClass)
        }
        .sheet(item: $activeSheetRoute, onDismiss: handleSheetDismissed) { route in
            sheetDestination(for: route, layoutClass: layoutClass)
                .environment(\.nnLayoutClass, layoutClass)
        }
    }

    private func todayPane(layoutClass: NNLayoutClass) -> some View {
        TodayView(
            store: store,
            selectedMealId: layoutClass.isDualPane ? selectedMealId : nil,
            onSelectMeal: { meal in
                withAnimation(reduceMotion ? nil : NNMotion.easeStandard) {
                    selectedMealId = meal.id
                }
                if !layoutClass.isDualPane {
                    activeSheetRoute = .mealDetail(meal.id)
                }
            },
            onOpenCapture: { mode in
                presentCapture(mode: mode, layoutClass: layoutClass)
            },
            onOpenSettings: {
                activeSheetRoute = .settings
            },
            onOpenImport: {
                activeSheetRoute = .importHistory
            }
        )
    }

    // MARK: - Modal Destinations

    @ViewBuilder
    private func fullScreenDestination(for route: FullScreenRoute, layoutClass: NNLayoutClass) -> some View {
        switch route {
        case let .capture(mode):
            captureDestination(mode: mode, layoutClass: layoutClass)

        case let .review(draft):
            ReviewView(
                store: store,
                draft: draft,
                onBack: {
                    queueCaptureAfterDismiss(mode: .photo, layoutClass: layoutClass)
                    activeFullScreenRoute = nil
                },
                onSaved: { meal in
                    activeFullScreenRoute = nil
                    handleSavedMeal(meal, layoutClass: layoutClass)
                }
            )
        }
    }

    @ViewBuilder
    private func sheetDestination(for route: SheetRoute, layoutClass: NNLayoutClass) -> some View {
        switch route {
        case let .capture(mode):
            captureDestination(mode: mode, layoutClass: layoutClass)

        case let .serving(context):
            ServingSheetView(
                store: store,
                context: context,
                onClose: {
                    activeSheetRoute = nil
                },
                onSaved: { meal in
                    activeSheetRoute = nil
                    handleSavedMeal(meal, layoutClass: layoutClass)
                }
            )

        case let .mealDetail(mealId):
            if let meal = store.todayMeals.first(where: { $0.id == mealId }) {
                MealDetailView(
                    store: store,
                    meal: meal,
                    embedded: false,
                    showCloseButton: true,
                    onClose: {
                        selectedMealId = nil
                        activeSheetRoute = nil
                    },
                    onDeleted: {
                        activeSheetRoute = nil
                        handleDeletedMeal()
                    }
                )
            } else {
                Color.clear
                    .onAppear {
                        selectedMealId = nil
                        activeSheetRoute = nil
                    }
            }

        case .settings:
            SettingsView(
                store: store,
                onClose: {
                    activeSheetRoute = nil
                },
                onOpenImport: {
                    pendingSheetRoute = .importHistory
                    activeSheetRoute = nil
                }
            )

        case .importHistory:
            ImportView(
                store: store,
                onClose: {
                    activeSheetRoute = nil
                },
                onCompleted: { summary in
                    activeSheetRoute = nil
                    handleImportCompleted(summary)
                }
            )
        }
    }

    private func captureDestination(mode: CaptureMode, layoutClass: NNLayoutClass) -> some View {
        CaptureView(
            store: store,
            initialMode: mode,
            onClose: {
                dismissCapture()
            },
            onOpenReview: { draft in
                pendingFullScreenRoute = .review(draft)
                dismissCapture()
            },
            onSelectFood: { context in
                pendingSheetRoute = .serving(context)
                dismissCapture()
            },
            onSavedPendingMeal: { meal in
                dismissCapture()
                if layoutClass.isDualPane {
                    selectedMealId = meal.id
                }
                showToast(
                    title: "Saved offline",
                    message: "We'll analyse this photo as soon as you're back online.",
                    tone: .neutral,
                    icon: .pending
                )
            }
        )
    }

    // MARK: - Navigation Chaining & Helpers

    private func useSheetForCapture(_ layoutClass: NNLayoutClass) -> Bool {
        layoutClass == .dualPane(isDuoUnfolded: false)
    }

    private func presentCapture(mode: CaptureMode, layoutClass: NNLayoutClass) {
        if useSheetForCapture(layoutClass) {
            activeSheetRoute = .capture(mode)
        } else {
            activeFullScreenRoute = .capture(mode)
        }
    }

    private func queueCaptureAfterDismiss(mode: CaptureMode, layoutClass: NNLayoutClass) {
        if useSheetForCapture(layoutClass) {
            pendingSheetRoute = .capture(mode)
        } else {
            pendingFullScreenRoute = .capture(mode)
        }
    }

    private func dismissCapture() {
        if case .capture = activeFullScreenRoute {
            activeFullScreenRoute = nil
        }
        if case .capture = activeSheetRoute {
            activeSheetRoute = nil
        }
    }

    private func handleSheetDismissed() {
        if activeSheetRoute == nil {
            // Keep selectedMealId in sync if the user swiped down on a compact meal sheet.
            if pendingSheetRoute == nil, pendingFullScreenRoute == nil {
                // Only clear selection when not transitioning into dual-pane mode.
                if let selectedMealId,
                   !store.todayMeals.contains(where: { $0.id == selectedMealId })
                {
                    self.selectedMealId = nil
                }
            }
        }
        drainPendingPresentations()
    }

    private func drainPendingPresentations() {
        if let nextFullScreen = pendingFullScreenRoute {
            pendingFullScreenRoute = nil
            activeFullScreenRoute = nextFullScreen
            return
        }
        if let nextSheet = pendingSheetRoute {
            pendingSheetRoute = nil
            activeSheetRoute = nextSheet
        }
    }

    private func pruneSelectedMealIfMissing() {
        if let selectedMealId,
           !store.todayMeals.contains(where: { $0.id == selectedMealId })
        {
            self.selectedMealId = nil
            if case .mealDetail = activeSheetRoute {
                activeSheetRoute = nil
            }
        }
    }

    private func handleSavedMeal(_ meal: Meal, layoutClass: NNLayoutClass) {
        if layoutClass.isDualPane {
            selectedMealId = meal.id
        }

        let summary = NNFormatting.metadataLine(
            meal.title,
            NNFormatting.kcalWithUnit(meal.totalNutrition.caloriesKcal)
        )
        showToast(
            title: "Saved to diary",
            message: summary,
            tone: .accent,
            icon: .checkCircle
        )

        if store.isSignedIn, !store.isOffline {
            Task {
                _ = try? await store.syncNow()
            }
        }
    }

    private func handleDeletedMeal() {
        selectedMealId = nil
        showToast(
            title: "Meal deleted",
            message: "Removed from your diary.",
            tone: .neutral,
            icon: .trash
        )
    }

    private func handleImportCompleted(_ summary: ImportSummary) {
        let unit = summary.importedCount == 1 ? "meal" : "meals"
        let detail: String
        if summary.skippedCount > 0 {
            detail = "\(NNFormatting.kcal(summary.importedCount)) \(unit) imported from \(summary.source) \u{00B7} \(NNFormatting.kcal(summary.skippedCount)) skipped."
        } else {
            detail = "\(NNFormatting.kcal(summary.importedCount)) \(unit) imported from \(summary.source)."
        }

        showToast(
            title: "Import complete",
            message: detail,
            tone: .info,
            icon: .importHistory
        )

        if store.isSignedIn, !store.isOffline {
            Task {
                _ = try? await store.syncNow()
            }
        }
    }

    private func applyLaunchCameraPreferenceIfNeeded(layoutClass: NNLayoutClass) {
        guard !hasAppliedLaunchCameraPreference else { return }
        hasAppliedLaunchCameraPreference = true
        if store.openToCamera {
            presentCapture(mode: .photo, layoutClass: layoutClass)
        }
    }

    private func resetSessionPresentationState() {
        activeFullScreenRoute = nil
        activeSheetRoute = nil
        pendingFullScreenRoute = nil
        pendingSheetRoute = nil
        selectedMealId = nil
        dismissToast()
    }

    private func showToast(title: String, message: String, tone: NNBannerTone, icon: NNIcon) {
        toastDismissTask?.cancel()
        let notice = ToastNotice(title: title, message: message, tone: tone, icon: icon)
        withAnimation(reduceMotion ? nil : NNMotion.easeStandard) {
            activeToast = notice
        }
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            dismissToast()
        }
    }

    private func dismissToast() {
        toastDismissTask?.cancel()
        toastDismissTask = nil
        withAnimation(reduceMotion ? nil : NNMotion.easeStandard) {
            activeToast = nil
        }
    }
}

// MARK: - Modal Route Descriptors

private enum FullScreenRoute: Identifiable, Sendable {
    case capture(CaptureMode)
    case review(ReviewDraft)

    var id: String {
        switch self {
        case let .capture(mode): "capture-\(mode.rawValue)"
        case let .review(draft): "review-\(draft.id.uuidString)"
        }
    }
}

private enum SheetRoute: Identifiable, Sendable {
    case capture(CaptureMode)
    case serving(ServingSelectionContext)
    case mealDetail(UUID)
    case settings
    case importHistory

    var id: String {
        switch self {
        case let .capture(mode): "sheet-capture-\(mode.rawValue)"
        case let .serving(context): "serving-\(context.id.uuidString)"
        case let .mealDetail(mealId): "meal-\(mealId.uuidString)"
        case .settings: "settings"
        case .importHistory: "import-history"
        }
    }
}

private struct ToastNotice: Equatable, Sendable {
    let id = UUID()
    let title: String
    let message: String
    let tone: NNBannerTone
    let icon: NNIcon
}
