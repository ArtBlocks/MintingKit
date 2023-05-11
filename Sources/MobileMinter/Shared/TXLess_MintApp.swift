//
//  TXLess_MintApp.swift
//  Shared
//
//  Created by Shantanu Bala on 3/15/22.
//

import StripeTerminal
import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  static var apiClient: APIClient?
  public let defaultCurrency = "USD"
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let apiClient = APIClient()
    Terminal.setTokenProvider(apiClient)
    Terminal.shared.delegate = TerminalDelegateAnnouncer.shared
    AppDelegate.apiClient = apiClient
    return true
  }
}

class AppState: ObservableObject {
  static let shared = AppState()

  @Published var sessionID = UUID()
  @Published var intentMintProject = false
  @Published var intentOpenProject = ""
}

@main
struct TXLess_MintApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var appState = AppState.shared
  var body: some Scene {
    WindowGroup {
      ContentView().id(appState.sessionID)
    }
  }
}
