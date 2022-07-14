import SwiftUI
import BetterSafariView
import LocalAuthentication
import KeychainSwift


private enum LoginError: Error {
    case tokenError(String)
}

public struct MintingLoginButton: View {
    @State private var startingWebAuthenticationSession = false
    let keychain = KeychainSwift()
    let label = "Sign in"
    let onSuccess: (String) -> ()
    let onFailure: (Error) -> ()
    
    public var body: some View {
        Button(label) {
            startingWebAuthenticationSession = true
        }.onAppear {
            DispatchQueue.main.async {
                guard let lastOpened = UserDefaults.standard.object(forKey: "LastOpened") as? Date else {
                    return
                }
                guard let elapsed = Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day else {
                    return
                }
                if elapsed >= 6 {
                    return
                }
                if let t = keychain.get("authToken") {
                    let context = LAContext()
                    var error: NSError?
                    
                    // check whether biometric authentication is possible
                    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                        // it's possible, so go ahead and use it
                        let reason = "We need to unlock your data."
                        
                        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                            // authentication has now completed
                            if success {
                                onSuccess(t)
                            } else {
                                // there was a problem
                            }
                        }
                    } else {
                        // no biometrics
                    }
                }
            }
        }
        .webAuthenticationSession(isPresented: $startingWebAuthenticationSession) {
            WebAuthenticationSession(
                url: URL(string: "https://minting-api.artblocks.io/app/?appauth=true")!,
                callbackURLScheme: "txlessauth"
            ) { callbackURL, error in
                if let t = callbackURL?.host {
                    DispatchQueue.main.async {
                        keychain.set(t, forKey: "authToken")
                        UserDefaults.standard.set(Date(), forKey: "LastOpened")
                    }
                    onSuccess(t)
                } else if let error = error {
                    onFailure(error)
                } else {
                    onFailure(LoginError.tokenError("Unable to retrieve token from login screen."))
                }
            }
        }
    }
}
