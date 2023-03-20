//
//  Haptics.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 7/1/22.
//

import Foundation
import UIKit

class Haptics {
  static let shared = Haptics()

  private init() {}

  func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
  }

  func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
    UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
  }
}
