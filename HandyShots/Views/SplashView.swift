//
//  SplashView.swift
//  HandyShots MVP
//
//  Created by Claude
//  Copyright © 2025. All rights reserved.
//

import SwiftUI

/// Animated splash screen shown on app launch
struct SplashView: View {
    // MARK: - State Properties

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    @State private var showSubtitle: Bool = false

    /// Callback when animation completes
    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Camera icon with animation
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)

                // HELLO text with animation
                Text("HELLO")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

                // Subtitle
                if showSubtitle {
                    Text("Welcome to HandyShots")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        // Main entrance animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
            scale = 1.0
            opacity = 1.0
        }

        // Rotation effect
        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            rotation = 360
        }

        // Show subtitle
        withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
            showSubtitle = true
        }

        // Exit animation and complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.0
                scale = 1.2
            }

            // Call completion after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(onComplete: {})
}
