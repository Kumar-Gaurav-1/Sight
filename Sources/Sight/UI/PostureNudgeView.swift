import SwiftUI

// MARK: - Apple-Authentic Posture Nudge

struct PostureNudgeView: View {
    var onDismiss: (() -> Void)?
    var autoDismissSeconds: Double = 4.0
    
    @State private var appear = false
    @State private var arrowUp = false
    @State private var countdown: Int
    @State private var dragY: CGFloat = 0
    @State private var timer: Timer?
    
    private let postureOrange = Color.orange
    
    init(onDismiss: (() -> Void)? = nil, autoDismissSeconds: Double = 4.0) {
        self.onDismiss = onDismiss
        self.autoDismissSeconds = autoDismissSeconds
        _countdown = State(initialValue: Int(autoDismissSeconds))
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Activity ring inspired icon
            ZStack {
                Circle()
                    .stroke(postureOrange.opacity(0.2), lineWidth: 4)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: appear ? 1 : 0)
                    .stroke(postureOrange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                ZStack {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                        .offset(x: 10, y: arrowUp ? -6 : -2)
                }
                .foregroundStyle(postureOrange)
            }
            .frame(width: 60, height: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Posture")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Sit up straight, shoulders back")
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
        
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            arrowUp = true
        }
        
        // Store timer reference for cleanup
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
        PostureNudgeView()
            .padding(.horizontal, 20)
        Spacer()
    }
    .padding(.top, 60)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.windowBackgroundColor))
}
