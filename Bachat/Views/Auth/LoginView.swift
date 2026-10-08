import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    // UI State for animations
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    @State private var isFocused = false // Simple focus state proxy
    
    var body: some View {
        ZStack {
            // Premium Animated-like Background
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                let size = proxy.size
                Circle()
                    .fill(
                        RadialGradient(colors: [Color.indigo.opacity(0.8), .clear], center: .center, startRadius: 0, endRadius: size.width)
                    )
                    .frame(width: size.width * 1.5, height: size.width * 1.5)
                    .offset(x: -size.width/2, y: -size.height/3)
                    .blur(radius: 50)
                
                Circle()
                    .fill(
                        RadialGradient(colors: [Color.purple.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: size.width * 0.8)
                    )
                    .frame(width: size.width * 1.2, height: size.width * 1.2)
                    .offset(x: size.width/2, y: size.height/2)
                    .blur(radius: 50)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 35) {
                // Logo/Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.cyan, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .cyan.opacity(0.5), radius: 15, x: 0, y: 5)
                        
                        Image(systemName: "indianrupeesign")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Text("Bachat")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .tracking(1.5)
                    
                    Text(isSignup ? "Create your account" : "Welcome back")
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.7))
                }
                .padding(.bottom, 10)
                
                // Form Container (Glassmorphism)
                VStack(spacing: 20) {
                    // Email Field
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.primary.opacity(0.5))
                            .frame(width: 20)
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundStyle(.primary)
                            .tint(.cyan)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Password Field
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.primary.opacity(0.5))
                            .frame(width: 20)
                        SecureField("Password", text: $password)
                            .foregroundStyle(.primary)
                            .tint(.cyan)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    
                    if let error = errorMessage {
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .foregroundStyle(.red)
                        .font(.footnote.weight(.medium))
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Submit Button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(isSignup ? "Create Account" : "Log In")
                                .font(.title3.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(
                        LinearGradient(colors: [.cyan, .indigo], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.primary)
                    .cornerRadius(16)
                    .shadow(color: .indigo.opacity(0.5), radius: 10, x: 0, y: 5)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 10)
                
                // Toggle Mode
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) { 
                        isSignup.toggle() 
                        errorMessage = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSignup ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(.primary.opacity(0.6))
                        Text(isSignup ? "Log in" : "Sign up")
                            .foregroundStyle(.cyan)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 20)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if isSignup {
                    try await authManager.signup(email: email, password: password)
                } else {
                    try await authManager.login(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
