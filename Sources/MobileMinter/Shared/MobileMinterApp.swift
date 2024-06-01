import StripeTerminal
import SwiftUI
import UIKit

@main
struct MobileMinterApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject var appState = AppState.shared

  var body: some Scene {
    WindowGroup {
      ContentView().id(appState.sessionID)
    }
  }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
  static var apiClient: APIClient?
  let defaultCurrency = "USD"

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    configureTerminal()
    return true
  }
}

// MARK: - AppDelegate (Private)
extension AppDelegate {
  fileprivate func configureTerminal() {
    let apiClient = APIClient()
    Terminal.setTokenProvider(apiClient)
    Terminal.shared.delegate = TerminalDelegateAnnouncer.shared
    Self.apiClient = apiClient
  }
}

// MARK: - AppState
class AppState: ObservableObject {
  static let shared = AppState()

  @Published var sessionID = UUID()
  @Published var intentMintProject = false
  @Published var intentOpenProject = ""
}
