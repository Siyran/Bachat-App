import SwiftUI
import SwiftData
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var showingPasswordAlert = false
    @State private var passwordMessage = ""
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            DashboardView(context: modelContext)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            // Add Expense
            NavigationStack {
                QuickExpenseView()
            }
            .tabItem {
                Label("Add", systemImage: "plus.circle.fill")
            }
            .tag(1)
            
            // Expenses
            NavigationStack {
                ExpenseListView()
            }
            .tabItem {
                Label("Expenses", systemImage: "list.bullet")
            }
            .tag(2)
            
            // Income
            NavigationStack {
                IncomeEntryView(context: modelContext)
            }
            .tabItem {
                Label("Income", systemImage: "indianrupeesign.circle")
            }
            .tag(3)
            
            // More
            NavigationStack {
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                    
                    GeometryReader { proxy in
                        let size = proxy.size
                        Circle()
                            .fill(RadialGradient(colors: [Color.indigo.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: size.width))
                            .frame(width: size.width * 1.5, height: size.width * 1.5)
                            .offset(x: size.width/4, y: -size.height/4)
                            .blur(radius: 50)
                    }
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack {
                                Text("More")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.bottom, 8)
                            
                            VStack(spacing: 2) {
                                Button(action: {
                                    withAnimation {
                                        isDarkMode.toggle()
                                    }
                                }) {
                                    moreRow(title: isDarkMode ? "Light Mode" : "Dark Mode", icon: isDarkMode ? "sun.max" : "moon", color: .yellow)
                                }
                                
                                NavigationLink(destination: SettingsView()) {
                                    moreRow(title: "Settings", icon: "gearshape", color: .gray)
                                }
                                
                                Button(action: {
                                    if let email = Auth.auth().currentUser?.email {
                                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                                            if let error = error {
                                                passwordMessage = error.localizedDescription
                                            } else {
                                                passwordMessage = "Password reset email sent to \(email)"
                                            }
                                            showingPasswordAlert = true
                                        }
                                    }
                                }) {
                                    moreRow(title: "Change Password", icon: "lock.rotation", color: .blue)
                                }
                                .alert("Change Password", isPresented: $showingPasswordAlert) {
                                    Button("OK", role: .cancel) { }
                                } message: {
                                    Text(passwordMessage)
                                }
                                
                                Button(action: {
                                    try? AuthManager.shared.signOut()
                                }) {
                                    moreRow(title: "Logout", icon: "rectangle.portrait.and.arrow.right", color: .red)
                                }
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20).stroke(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
                
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(4)
        }
    }
    
    private func moreRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
            }
            
            Text(title)
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.primary.opacity(0.4))
                .font(.subheadline)
        }
        .padding(16)
        .background(Color.primary.opacity(0.01))
    }
}
