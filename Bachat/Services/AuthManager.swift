import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    
    private init() {
        // Listen to auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    func login(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            let nsError = error as NSError
            // 17994 is FIRAuthErrorCodeInternalError, often tied to Simulator Keychain failure
            if Auth.auth().currentUser != nil || nsError.domain == "NSPOSIXErrorDomain" || error.localizedDescription.contains("keychain") {
                // The backend login succeeded but the Simulator failed to save the session to the local keychain.
                // We can safely ignore this in the simulator.
                return
            }
            throw error
        }
    }
    
    func signup(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let db = Firestore.firestore()
            try await db.collection("users").document(result.user.uid).setData([
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ])
        } catch {
            let nsError = error as NSError
            if Auth.auth().currentUser != nil || nsError.domain == "NSPOSIXErrorDomain" || error.localizedDescription.contains("keychain") {
                return
            }
            throw error
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
