import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep: OnboardingStep = .identity
    @State private var draft = OnboardingDraft()
    @State private var appeared = false
    @State private var saveErrorMessage: String?
    @State private var errorDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            switch currentStep {
            case .identity:
                OnboardingIdentityStep(draft: $draft) {
                    saveBabyAndAdvance()
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            case .permissions:
                OnboardingPermissionsStep {
                    completeOnboarding()
                }
            }

            VStack {
                Spacer()
                saveFeedback
            }
            .padding(.horizontal, AppTheme.Spacing.screenHorizontal)
            .padding(.bottom, 20)
        }
        .animation(.easeInOut(duration: 0.8), value: currentStep)
        .onAppear {
            let repo = BabyRepository(modelContext: modelContext)
            OnboardingMigration.migrateIfNeeded(
                babyRepository: repo,
                defaults: UserDefaults.standard
            )

            withAnimation(.easeInOut(duration: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
            errorDismissTask?.cancel()
            errorDismissTask = nil
        }
    }

    private func saveBabyAndAdvance() {
        let repo = BabyRepository(modelContext: modelContext)
        guard repo.createDefaultIfNeeded() else {
            showSaveError()
            return
        }
        guard repo.updateName(draft.trimmedName) else {
            showSaveError()
            return
        }
        guard repo.updateBirthDate(draft.birthDate) else {
            showSaveError()
            return
        }

        withAnimation {
            currentStep = .permissions
        }
    }

    private func completeOnboarding() {
        let repo = BabyRepository(modelContext: modelContext)
        guard repo.markOnboardingCompleted() else {
            showSaveError()
            return
        }

        withAnimation(.easeInOut(duration: 0.6)) {
            hasCompletedOnboarding = true
        }
    }

    @ViewBuilder
    private var saveFeedback: some View {
        if let saveErrorMessage {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                Text(saveErrorMessage)
                    .font(AppTheme.Typography.meta)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.Colors.cardBackground.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .transition(.opacity)
        }
    }

    private func showSaveError() {
        saveErrorMessage = L10n.text(
            "onboarding.save_error",
            en: "We couldn't save this step. Please try again.",
            zh: "这一步没有保存成功，请再试一次。"
        )
        scheduleErrorDismiss()
    }

    private func scheduleErrorDismiss() {
        errorDismissTask?.cancel()
        errorDismissTask = Task {
            do {
                try await Task.sleep(for: .seconds(3))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            saveErrorMessage = nil
            errorDismissTask = nil
        }
    }
}
