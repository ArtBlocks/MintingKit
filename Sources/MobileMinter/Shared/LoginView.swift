//
//  LoginView.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 3/17/22.
//

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
    }.onAppear {
      DispatchQueue.main.async {
        guard let lastOpened = UserDefaults.standard.object(forKey: "LastOpened") as? Date else {
          return
        }
        guard
          let elapsed = Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day
        else {
          return
        }
        if elapsed >= 6 {
          return
        }
        if let t = keychain.get("authToken") {
          self.currentToken = t
          let context = LAContext()
          var error: NSError?

          // check whether biometric authentication is possible
          if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(
              .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, authenticationError in
              // authentication has now completed
              if success {
                currentScreen = .projects
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
        currentToken = callbackURL?.host
        if let t = currentToken {
          DispatchQueue.main.async {
            keychain.set(t, forKey: "authToken")
            UserDefaults.standard.set(Date(), forKey: "LastOpened")
          }
          currentScreen = .projects
        }
      }
    }
  }
}

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(currentToken: .constant(nil), currentScreen: .constant(.login))
  }
}
