//
//  ContentView.swift
//  Shared
//
//  Created by Shantanu Bala on 3/15/22.
//

import SwiftUI

enum ScreenID {
  case login
  case projects
  case minting
}

struct ContentView: View {
  // the current authentication token for the user
  @State var currentToken: String? = nil

  // the current PBAB project being minted
  @State var currentProject: Project? = nil

  // the current screen displayed to the user
  @State var currentScreen: ScreenID = .login

  var body: some View {
    NavigationView {
      if currentScreen == .login {
        LoginView(currentToken: $currentToken, currentScreen: $currentScreen).navigationTitle(
          "Login")
      } else if currentScreen == .projects {
        ProjectsView(
          currentToken: $currentToken, currentProject: $currentProject,
          currentScreen: $currentScreen
        ).navigationTitle("Projects")
      } else if currentScreen == .minting {
        MintingView(
          currentToken: $currentToken, currentScreen: $currentScreen,
          currentProject: $currentProject
        ).navigationTitle(currentProject?.title ?? "Minting")
      }
    }.navigationViewStyle(StackNavigationViewStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
