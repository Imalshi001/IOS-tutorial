
import SwiftUI
import Combine

struct ContentView: View {

    enum GamePhase {
        case idle, playing, over
    }

    @State private var score = 0
    @State private var timeRemaining = 10
    @State private var phase: GamePhase = .idle

    // Combo system
    @State private var lastTapTime: Date? = nil
    @State private var comboMultiplier = 1

    // Moving target
    @State private var targetOffset = CGSize.zero

    @AppStorage("highScore") private var highScore = 0
    @AppStorage("gamesPlayed") private var gamesPlayed = 0

    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

    private let background = Color(
        red: 0.055,
        green: 0.035,
        blue: 0.12
    )

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            // Background glow
            Circle()
                .fill(Color.purple.opacity(0.18))
                .frame(width: 320)
                .blur(radius: 100)
                .offset(x: 150, y: -280)

            Circle()
                .fill(Color.pink.opacity(0.12))
                .frame(width: 280)
                .blur(radius: 100)
                .offset(x: -150, y: 300)

            VStack(spacing: 0) {

                header

                Spacer(minLength: 30)

                if phase == .over {
                    gameOverView
                } else {
                    gameView
                }

                Spacer(minLength: 30)

                footer
            }
            .padding(.horizontal, 25)
            .padding(.top, 18)
            .padding(.bottom, 15)
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in

            guard phase == .playing else { return }

            // Move target randomly every second
            moveTarget()

            if timeRemaining > 0 {
                timeRemaining -= 1
            }

            if timeRemaining == 0 {
                endGame()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {

            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("TAP FRENZY")
                    .font(.system(size: 19, weight: .black))
                    .tracking(1.5)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }

    // MARK: Main Game

    private var gameView: some View {
        VStack(spacing: 30) {

            // Score card
            VStack(spacing: 8) {

                Text("YOUR SCORE")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.5))

                HStack(alignment: .center, spacing: 12) {

                    Text(String(format: "%03d", score))
                        .font(.system(size: 76, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .purple.opacity(0.4), radius: 20)

                    // Combo multiplier display
                    if comboMultiplier >= 2 {
                        Text("x\(comboMultiplier)!")
                            .font(.system(size: 25, weight: .black))
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.18))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25), value: comboMultiplier)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 25)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )

            // Timer card
            HStack(spacing: 20) {

                ZStack {

                    Circle()
                        .stroke(
                            Color.white.opacity(0.10),
                            lineWidth: 6
                        )

                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / 10)
                        .stroke(
                            AngularGradient(
                                colors: [.pink, .purple, .cyan],
                                center: .center
                            ),
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(timeRemaining)")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 5) {

                    Text("TIME LEFT")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.45))

                    Text(
                        phase == .idle
                        ? "Ready to play?"
                        : "Keep the pace!"
                    )
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                }

                Spacer()

                Text("00:\(String(format: "%02d", timeRemaining))")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.pink)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.055))
            )

            // Main Tap Button - Moving Target
            Button(action: handleTap) {

                ZStack {

                    Circle()
                        .fill(Color.purple.opacity(0.13))
                        .frame(width: 255, height: 255)

                    Circle()
                        .stroke(
                            Color.purple.opacity(0.35),
                            lineWidth: 2
                        )
                        .frame(width: 230, height: 230)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.30, blue: 1),
                                    Color(red: 0.55, green: 0.20, blue: 0.95),
                                    Color(red: 0.35, green: 0.20, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 205, height: 205)
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.4),
                                    lineWidth: 3
                                )
                                .padding(5)
                        )
                        .shadow(
                            color: .purple.opacity(0.55),
                            radius: 30,
                            y: 12
                        )

                    Text("TAP!")
                        .font(.system(size: 30, weight: .black))
                        .tracking(3)
                        .foregroundStyle(.white)
                }
                .frame(width: 260, height: 260)
                .offset(
                    x: targetOffset.width,
                    y: targetOffset.height
                )
                .animation(
                    .easeInOut(duration: 0.35),
                    value: targetOffset
                )
            }
            .buttonStyle(.plain)
            .disabled(phase == .over)
            .frame(height: 260)

            Text(
                phase == .idle
                ? "TAP TO START THE COUNTDOWN"
                : "GO GO GO! EVERY TAP COUNTS"
            )
            .font(.system(size: 10, weight: .heavy))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.45))

            if comboMultiplier >= 2 {
                Text("FAST TAPPING COMBO!")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.yellow)
                    .transition(.opacity)
            }
        }
    }

    // MARK: Game Over

    private var gameOverView: some View {
        VStack(spacing: 25) {

            Circle()
                .fill(Color.orange.opacity(0.12))
                .frame(width: 110, height: 110)
                .overlay(
                    Text("WIN!")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.orange)
                )

            VStack(spacing: 8) {

                Text("TIME'S UP!")
                    .font(.system(size: 35, weight: .black))
                    .foregroundStyle(.white)

                Text("THAT WAS INTENSE.")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.45))
            }

            VStack(spacing: 8) {

                Text("YOUR FINAL SCORE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))

                Text(String(format: "%03d", score))
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            HStack {

                Text("PERSONAL BEST")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.65))

                Spacer()

                Text("\(highScore)")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.yellow)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))
            )

            Button(action: resetGame) {

                Text("PLAY AGAIN")
                    .tracking(2)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .shadow(
                        color: .purple.opacity(0.35),
                        radius: 18,
                        y: 8
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.045))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 0) {

            statItem(
                title: "BEST SCORE",
                value: "\(highScore)",
                color: .yellow
            )

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 40)

            statItem(
                title: "GAMES PLAYED",
                value: "\(gamesPlayed)",
                color: .purple
            )
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func statItem(
        title: String,
        value: String,
        color: Color
    ) -> some View {

        VStack(spacing: 6) {

            Text(title)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 23, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Game Logic

    private func handleTap() {

        guard phase != .over else { return }

        let currentTime = Date()

        // Check time between consecutive taps
        if let previousTap = lastTapTime {

            let timeDifference = currentTime.timeIntervalSince(previousTap)

            if timeDifference <= 0.3 {
                // Fast tap: increase combo
                comboMultiplier += 1
            } else {
                // Slow tap: reset combo
                comboMultiplier = 1
            }

        } else {
            comboMultiplier = 1
        }

        lastTapTime = currentTime

        switch phase {

        case .idle:

            score = 1
            phase = .playing

        case .playing:

            // Award points based on combo multiplier
            score += comboMultiplier

        case .over:

            break
        }
    }

    // MARK: Moving Target Logic

    private func moveTarget() {

        let randomX = CGFloat.random(in: -35...35)
        let randomY = CGFloat.random(in: -15...15)

        withAnimation(.easeInOut(duration: 0.35)) {

            targetOffset = CGSize(
                width: randomX,
                height: randomY
            )
        }
    }

    // MARK: End Game

    private func endGame() {

        guard phase == .playing else { return }

        phase = .over

        gamesPlayed += 1

        if score > highScore {
            highScore = score
        }
    }

    // MARK: Reset Game

    private func resetGame() {

        score = 0
        timeRemaining = 10
        phase = .idle

        // Reset combo
        lastTapTime = nil
        comboMultiplier = 1

        // Reset target position
        targetOffset = .zero
    }
}

#Preview {
    ContentView()
}

