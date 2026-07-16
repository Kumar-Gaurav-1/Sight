import SwiftUI

@MainActor
public class NudgeState: ObservableObject {
    @Published public var dragY: CGFloat = 0
    @Published public var isDismissing: Bool = false
    public var timer: Timer?

    public init() {}

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    public func performDismissAction(action: (() -> Void)?) {
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
}

public struct NudgeModifier: ViewModifier {
    @ObservedObject var state: NudgeState
    var onDismiss: () -> Void

    public init(state: NudgeState, onDismiss: @escaping () -> Void) {
        self.state = state
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .offset(y: state.dragY)
            .gesture(
                DragGesture()
                    .onChanged { state.dragY = min(0, $0.translation.height * 0.6) }
                    .onEnded { value in
                        if value.translation.height < -30 {
                            onDismiss()
                        } else {
                            withAnimation(.spring(response: 0.3)) { state.dragY = 0 }
                        }
                    }
            )
            .onTapGesture { onDismiss() }
            .onDisappear { state.stopTimer() }
    }
}

public extension View {
    func nudgeBehavior(state: NudgeState, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(NudgeModifier(state: state, onDismiss: onDismiss))
    }
}
