import Foundation

struct StripeCountries {
  static let supportedByTerminal: [String] = [
    "US",
    "CA",
    "SG",
    "GB",
    "IE",
    "AU",
    "NZ",
    "FR",
    "DE",
    "NL",
    "BE",
    "AT",
    "ES",
    "DK",
    "IT",
    "SE",
    "LU",
    "PT",
    "NO",
    "FI",
    "CH",
  ]

  static func countryName(forRegionCode code: String) -> String? {
    if let countryName = Locale.current.localizedString(forRegionCode: code) {
      return countryName
    }
    return nil
  }
}
