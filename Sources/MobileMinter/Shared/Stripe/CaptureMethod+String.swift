import StripeTerminal

extension CaptureMethod {
  func toString() -> String {
    switch self {
    case .automatic:
      return "automatic"
    case .manual:
      return "manual"
    @unknown default:
      fatalError()
    }
  }
}
