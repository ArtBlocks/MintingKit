//
//  PaymentViewControllerView.swift
//  MobileMinter
//
//  Created by Shantanu Bala on 3/7/23.
//

import StripeTerminal
import SwiftUI

struct PaymentViewControllerView: UIViewControllerRepresentable {
  let priceAmountCents: UInt
  let action: () -> Void
  typealias UIViewControllerType = PaymentViewController

  private func makePaymentMethodOptionsParameters() -> PaymentMethodOptionsParameters {
    let cardPresentParams: CardPresentParameters = CardPresentParameters(
      requestExtendedAuthorization: false,
      requestIncrementalAuthorizationSupport: false)
    return PaymentMethodOptionsParameters(cardPresentParameters: cardPresentParams)
  }

  func makeUIViewController(context: Context) -> PaymentViewController {
    let captureMethod = CaptureMethod.automatic
    var paymentMethodTypes = ["card_present"]

    let paymentParams = PaymentIntentParameters(
      amount: priceAmountCents,
      currency: "usd",
      paymentMethodTypes: paymentMethodTypes,
      captureMethod: captureMethod)

    paymentParams.paymentMethodOptionsParameters = makePaymentMethodOptionsParameters()

    // Set up destination payment
    let collectConfig = CollectConfiguration(skipTipping: false, updatePaymentIntent: false)
    let vc = PaymentViewController(
      paymentParams: paymentParams,
      collectConfig: collectConfig,
      action: action
    )
    // Do some configurations here if needed.
    return vc
  }

  init(priceAmountCents: UInt, action: @escaping () -> Void) {
    self.priceAmountCents = priceAmountCents
    self.action = action
  }

  func updateUIViewController(_ uiViewController: PaymentViewController, context: Context) {
  }
}
