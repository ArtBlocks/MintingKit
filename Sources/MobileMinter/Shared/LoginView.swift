import BetterSafariView
import LocalAuthentication
import MintingKit
import SwiftUI

struct LoginView: View {
  @State private var startingWebAuthenticationSession = false
  @Binding var currentToken: String?
  @Binding var currentScreen: ScreenID
  let keychain = KeychainSwift()

  var body: some View {
    Form {
      Button("Sign in") {
        startingWebAuthenticationSession = true
      }
    }
    .onAppear(perform: retrieveSavedAuthenticationToken)
    .webAuthenticationSession(isPresented: $startingWebAuthenticationSession) {
      WebAuthenticationSession(
        url: URL(string: "https://minting-api.artblocks.io/app/?appauth=true")!,
        callbackURLScheme: "txlessauth"
      ) { callbackURL, error in
        handleWebAuthentication(callbackURL: callbackURL)
      }
    }
  }

  private func retrieveSavedAuthenticationToken() {
    guard let lastOpened = UserDefaults.standard.object(forKey: "LastOpened") as? Date else {
      return
    }

    let elapsed = daysElapsed(from: lastOpened, to: Date())

    if elapsed < 6, let savedToken = keychain.get("authToken") {
      currentToken = savedToken
      authenticateUser()
    }
  }

  private func daysElapsed(from startDate: Date, to endDate: Date) -> Int {
    Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
  }

  private func authenticateUser() {
    let context = LAContext()
    var error: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "We need to unlock your data."
      ) { success, authenticationError in
        if success {
          DispatchQueue.main.async {
            currentScreen = .projects
          }
        }
      }
    }
  }

  private func handleWebAuthentication(callbackURL: URL?) {
    currentToken = callbackURL?.host
    if let t = currentToken {
      DispatchQueue.main.async {
        keychain.set(t, forKey: "authToken")
        UserDefaults.standard.set(Date(), forKey: "LastOpened")
        currentScreen = .projects
      }
    }
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(currentToken: .constant(nil), currentScreen: .constant(.login))
  }
}
