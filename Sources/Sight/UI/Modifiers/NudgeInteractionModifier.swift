import SwiftUI

/// Helper function to encapsulate the duplicated dismiss animation and state logic.
func executeNudgeDismiss(
    isDismissing: Binding<Bool>,
    dragY: Binding<CGFloat>,
    stopTimer: @escaping () -> Void,
    completion: @escaping () -> Void
) {
    guard !isDismissing.wrappedValue else { return }
    isDismissing.wrappedValue = true

    stopTimer()
    withAnimation(.spring(response: 0.3)) {
        dragY.wrappedValue = -60
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        completion()
    }
}

struct NudgeInteractionModifier: ViewModifier {
    @Binding var dragY: CGFloat
    @Binding var isDismissing: Bool
    let stopTimer: () -> Void
    let onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .offset(y: dragY)
            .gesture(
                DragGesture()
                    .onChanged { dragY = min(0, $0.translation.height * 0.6) }
                    .onEnded { value in
                        if value.translation.height < -30 {
                            performAction { onDismiss?() }
                        } else {
                            withAnimation(.spring(response: 0.3)) { dragY = 0 }
                        }
                    }
            )
            .onTapGesture { performAction { onDismiss?() } }
    }

    private func performAction(_ action: @escaping () -> Void) {
        executeNudgeDismiss(
            isDismissing: $isDismissing,
            dragY: $dragY,
            stopTimer: stopTimer,
            completion: action
        )
    }
}

extension View {
    func nudgeInteraction(
        dragY: Binding<CGFloat>,
        isDismissing: Binding<Bool>,
        stopTimer: @escaping () -> Void,
        onDismiss: (() -> Void)?
    ) -> some View {
        modifier(NudgeInteractionModifier(
            dragY: dragY,
            isDismissing: isDismissing,
            stopTimer: stopTimer,
            onDismiss: onDismiss
        ))
    }
}
