//
//  MintProjectToken.swift
//  MobileMinter
//
//  Created by Shantanu Bala on 5/11/23.
//

import AppIntents
import Foundation

struct OpenProject: AppIntent {
  static var title: LocalizedStringResource = "Open Project"
  static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

  @Parameter(title: "Project Name")
  var projectName: String

  @MainActor
  func perform() async throws -> some IntentResult {
    AppState.shared.intentOpenProject = projectName
    return .result()
  }
}
