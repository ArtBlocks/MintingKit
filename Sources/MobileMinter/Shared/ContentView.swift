import SwiftUI

enum ScreenID {
  case login
  case projects
  case minting
}

struct ContentView: View {
  @State var currentToken: String? = nil
  @State var currentProject: Project? = nil
  @State var currentScreen: ScreenID = .login

  var body: some View {
    NavigationStack {
      currentView.navigationTitle(currentViewTitle)
    }
  }

  private var currentView: some View {
    switch currentScreen {
    case .login:
      return AnyView(LoginView(currentToken: $currentToken, currentScreen: $currentScreen))
    case .projects:
      return AnyView(
        ProjectsView(
          currentToken: $currentToken, currentProject: $currentProject,
          currentScreen: $currentScreen))
    case .minting:
      return AnyView(
        MintingView(
          currentToken: $currentToken, currentScreen: $currentScreen,
          currentProject: $currentProject))
    }
  }

  private var currentViewTitle: String {
    switch currentScreen {
    case .login:
      return "Login"
    case .projects:
      return "Projects"
    case .minting:
      return currentProject?.title ?? "Minting"
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
