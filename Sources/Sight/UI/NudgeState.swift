import SwiftUI

final class NudgeState: ObservableObject {
    @Published var isDismissing = false
    @Published var dragY: CGFloat = 0

    func dismiss(
        stopTimer: () -> Void,
        immediateAction: (() -> Void)? = nil,
        delayedAction: @escaping () -> Void
    ) {
        guard !isDismissing else { return }
        isDismissing = true
        stopTimer()
        immediateAction?()
        withAnimation(.spring(response: 0.3)) {
            dragY = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            delayedAction()
        }
    }
}

struct NudgeGestureModifier: ViewModifier {
    @ObservedObject var nudgeState: NudgeState
    let stopTimer: () -> Void
    let onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .offset(y: nudgeState.dragY)
            .gesture(
                DragGesture()
                    .onChanged { nudgeState.dragY = min(0, $0.translation.height * 0.6) }
                    .onEnded { value in
                        if value.translation.height < -30 {
                            nudgeState.dismiss(stopTimer: stopTimer) { onDismiss?() }
                        } else {
                            withAnimation(.spring(response: 0.3)) { nudgeState.dragY = 0 }
                        }
                    }
            )
            .onTapGesture {
                nudgeState.dismiss(stopTimer: stopTimer) { onDismiss?() }
            }
    }
}

extension View {
    func nudgeGestures(state: NudgeState, stopTimer: @escaping () -> Void, onDismiss: (() -> Void)?) -> some View {
        self.modifier(NudgeGestureModifier(nudgeState: state, stopTimer: stopTimer, onDismiss: onDismiss))
    }
}
