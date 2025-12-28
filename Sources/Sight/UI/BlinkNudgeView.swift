import SwiftUI

// MARK: - Apple-Authentic Blink Nudge

struct BlinkNudgeView: View {
    var onDismiss: (() -> Void)?
    var autoDismissSeconds: Double = 4.0
    
    @State private var appear = false
    @State private var breathe = false
    @State private var countdown: Int
    @State private var dragY: CGFloat = 0
    @State private var timer: Timer?
    
    init(onDismiss: (() -> Void)? = nil, autoDismissSeconds: Double = 4.0) {
        self.onDismiss = onDismiss
        self.autoDismissSeconds = autoDismissSeconds
        _countdown = State(initialValue: Int(autoDismissSeconds))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Breathing circle
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .offset(x: breathe ? cos(Double(i) * .pi / 3) * 8 : 0,
                                y: breathe ? sin(Double(i) * .pi / 3) * 8 : 0)
                }
                
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "eye")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Blink")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Look away and blink slowly")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 12)
            
            // Countdown
            Text("\(countdown)")
                .font(.system(size: 24, weight: .light, design: .rounded))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
                .frame(width: 30)
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        )
        .overlay(
            Capsule()
                .strokeBorder(.quaternary, lineWidth: 0.5)
        )
        .scaleEffect(appear ? 1 : 0.92)
        .opacity(appear ? 1 : 0)
        .offset(y: dragY)
        .gesture(
            DragGesture()
                .onChanged { dragY = min(0, $0.translation.height * 0.6) }
                .onEnded { value in
                    if value.translation.height < -30 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragY = 0 }
                    }
                }
        )
        .onTapGesture { dismiss() }
        .onAppear { startTimers() }
        .onDisappear { stopTimer() }
    }
    
    private func startTimers() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            appear = true
        }
        
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            breathe = true
        }
        
        // Countdown timer - store reference for cleanup
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] t in
            if countdown > 1 {
                countdown -= 1
            } else {
                t.invalidate()
                dismiss()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func dismiss() {
        stopTimer()
        withAnimation(.spring(response: 0.3)) {
            appear = false
            dragY = -60
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss?()
        }
    }
}

#Preview {
    VStack {
        BlinkNudgeView()
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
