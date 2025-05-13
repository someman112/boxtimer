import SwiftUI

// Animated Angular Gradient that adapts to Work/Rest state
struct AngularGradientView: View {
    var isWorking: Bool
    var isResting: Bool
    var isRunning: Bool
    var isMirrored: Bool = false // optional for left/right out-of-phase effect

    @State private var centerY: CGFloat = 0.792
    @State private var isPulsingUp = true
    @State private var pulseTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    let workingColors = [
        Color(hue: 0.33, saturation: 0.2, brightness: 0.35),
        Color(hue: 0.35, saturation: 1.0, brightness: 0.85)
    ]

    let restingColors = [
        Color(hue: 0.0, saturation: 0.2, brightness: 0.35),
        Color(hue: 0.0, saturation: 1.0, brightness: 0.85)
    ]

    var gradientColors: [Color] {
        isWorking ? workingColors : restingColors
    }

    var body: some View {
        AngularGradient(
            gradient: Gradient(colors: gradientColors),
            center: .init(x: 0.97, y: centerY)
        )
        .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
        .ignoresSafeArea()
        .onReceive(pulseTimer) { _ in
            guard isRunning else { return }

            withAnimation(.easeInOut(duration: 1.5)) {
                isPulsingUp.toggle()

                if isWorking {
                    // Both sides in sync
                    centerY = isPulsingUp ? 0.99 : 0.01
                } else if isResting {
                    // One side up, one down based on `isMirrored`
                    centerY = isPulsingUp
                    ? (isMirrored ? 0.5 : 0.75)
                        : (isMirrored ? 0.75 : 0.5)
                }
            }
        }
    }
}

struct MaskedTimeField: View {
    @Binding var totalSeconds: Double
    @State private var text: String = "00:00"

    var minSeconds = 0
    var maxSeconds = 120 * 60

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: 80, height: 35)
            .padding(.horizontal, 6)
            .background(Color.white)
            .foregroundColor(.black)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
            )
            .onAppear { syncText() }
            .onChange(of: text) { newValue in
                let digits = newValue.filter(\.isNumber)
                let last4 = String(digits.suffix(4))
                let padded = String(repeating: "0", count: 4 - last4.count) + last4

                let mm = Int(padded.prefix(2)) ?? 0
                var ss = Int(padded.suffix(2)) ?? 0
                ss = min(ss, 59)

                let formatted = String(format: "%02d:%02d", mm, ss)
                if formatted != text {
                    text = formatted
                }

                var total = mm * 60 + ss
                total = min(max(total, minSeconds), maxSeconds)
                totalSeconds = Double(total)
            }
    }

    private func syncText() {
        let t = max(minSeconds, min(maxSeconds, Int(totalSeconds)))
        let m = t / 60, s = t % 60
        text = String(format: "%02d:%02d", m, s)
    }
}

struct ContentView: View {
    @StateObject private var timerVM = WorkoutTimer()
    @GestureState private var isPressedStart = false
    @GestureState private var isPressedPause = false
    var body: some View {
        ZStack{
            
            HStack(spacing: 0) {
                AngularGradientView(
                    isWorking: timerVM.isWorking,
                    isResting: timerVM.isResting,
                    isRunning: timerVM.isRunning,
                    isMirrored: true
                )
                
                AngularGradientView(
                    isWorking: timerVM.isWorking,
                    isResting: timerVM.isResting,
                    isRunning: timerVM.isRunning,
                    isMirrored: false
                )
            }
            
            VStack(spacing: 30) {
                Spacer()

                // Countdown Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 12)
                        .frame(width: 180, height: 180)

                    Circle()
                        .trim(from: 0, to: timerVM.progress)
                        .stroke(Color.white, style: .init(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: timerVM.progress)
                        .frame(width: 180, height: 180)

                    Text(timeString(timerVM.timeRemaining))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.white.opacity(0.3)).cornerRadius(15)
                        Rectangle()
                            .fill(Color.white)
                            .cornerRadius(15)
                            .frame(width: geo.size.width * CGFloat(timerVM.progress))
                            .animation(.linear, value: timerVM.timeRemaining)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 40)

                // Config
                VStack(spacing: 16) {
                    HStack {
                        Text("Rounds: \(timerVM.totalRounds - (timerVM.currentRound-1))")
                            .font(.system(size:20, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Stepper("", value: $timerVM.totalRounds, in: 1...20)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Work Time:").foregroundColor(.white)
                            .font(.system(size:20, weight: .regular))
                                  
                        Spacer()
                        ZStack{
                            Rectangle()
                                .fill(Color.black)
                                .frame(width:80, height:35)
                                .offset(x:10, y:5)
                            
                            MaskedTimeField(totalSeconds:$timerVM  .roundTime)
                        }
                        
                    }

                    HStack {
                        Text("Rest:").foregroundColor(.white)
                            .font(.system(size:20, weight: .regular))
                        
                        Spacer()
                        ZStack{
                            Rectangle()
                                .fill(Color.black)
                                .frame(width:80, height:35)
                                .offset(x:10, y:5)
                            
                            MaskedTimeField(totalSeconds: $timerVM.restTime)
                    }
                    }
                }
                .padding(.horizontal, 40)

                // Controls
                HStack(spacing: 40) {
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 100, height: 50)
                            .offset(x: 7, y: 7)

                        Text("Start")
                            .frame(width: 100, height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .offset(x: isPressedStart ? 7 : 0, y: isPressedStart ? 7 : 0)
                            .animation(.easeInOut(duration: 0.45), value: isPressedStart)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($isPressedStart) { _, state, _ in
                                        state = true
                                    }
                                    .onEnded { _ in
                                        timerVM.start()
                                    }
                            )
                    }
                    
                        
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 100, height: 50)
                            .offset(x: -7, y: 7)

                        Text(timerVM.isRunning ? "Pause" : "Reset")
                            .frame(width: 100, height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .offset(x: isPressedPause ? -7 : 0, y: isPressedPause ? 7 : 0)
                            .animation(.easeInOut(duration: 0.45), value: isPressedPause)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($isPressedPause) { _, state, _ in
                                        state = true
                                    }
                                    .onEnded { _ in
                                        timerVM.isRunning ? timerVM.pause() : timerVM.reset()
                                    }
                            )
                    }


                }

                Spacer()
            }
            .padding(.top, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear { timerVM.reset() }
        }
    }

    private func timeString(_ seconds: Double) -> String {
        let t = max(0, Int(seconds))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}

#Preview {
    ContentView()
}
