//
//  MintProjectToken.swift
//  MobileMinter
//
//  Created by Shantanu Bala on 5/11/23.
//

import AppIntents
import Foundation

struct MintProjectToken: AppIntent {
  static var title: LocalizedStringResource = "Mint Project"
  static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

  @MainActor
  func perform() async throws -> some IntentResult {
    AppState.shared.intentMintProject = true
    return .result()
  }
}
