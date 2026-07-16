import SwiftUI
import Combine

@MainActor
class NudgeState: ObservableObject {
    @Published var dragY: CGFloat = 0
    @Published var isDismissing = false
    @Published var countdown: Int

    private var timer: Timer?

    init(autoDismissSeconds: Double) {
        self.countdown = Int(autoDismissSeconds)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func animateDismiss(action: (() -> Void)?) {
        guard !isDismissing else { return }
        isDismissing = true

        stopTimer()
        withAnimation(.spring(response: 0.3)) {
            dragY = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            action?()
        }
    }

    func startTimer(onDismiss: (() -> Void)?) {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let strongSelf = self else {
                    t.invalidate()
                    return
                }

                guard !strongSelf.isDismissing else {
                    t.invalidate()
                    return
                }

                if strongSelf.countdown > 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        strongSelf.countdown -= 1
                    }
                } else {
                    t.invalidate()
                    strongSelf.animateDismiss(action: onDismiss)
                }
            }
        }
    }
}

struct NudgeDismissModifier: ViewModifier {
    @ObservedObject var state: NudgeState
    var onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .offset(y: state.dragY)
            .gesture(
                DragGesture()
                    .onChanged { state.dragY = min(0, $0.translation.height * 0.6) }
                    .onEnded { value in
                        if value.translation.height < -30 {
                            state.animateDismiss(action: onDismiss)
                        } else {
                            withAnimation(.spring(response: 0.3)) { state.dragY = 0 }
                        }
                    }
            )
            .onTapGesture { state.animateDismiss(action: onDismiss) }
    }
}

extension View {
    func nudgeDismiss(state: NudgeState, onDismiss: (() -> Void)?) -> some View {
        self.modifier(NudgeDismissModifier(state: state, onDismiss: onDismiss))
    }
}
