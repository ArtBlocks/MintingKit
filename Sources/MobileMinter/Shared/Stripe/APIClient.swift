import Alamofire
import Foundation
import StripeTerminal

class APIClient: NSObject, ConnectionTokenProvider {
  var currentToken: String?
  private var baseURL: URL {
    if let url = URL(string: "https://minting-api.artblocks.io/") {
      return url
    } else {
      fatalError()
    }
  }

  // MARK: ConnectionTokenProvider
  func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
    let headers: HTTPHeaders = [
      "Authorization": "Token " + (currentToken ?? ""),
      "Accept": "application/json",
    ]
    let url = self.baseURL.appendingPathComponent("minting/stripe_terminal_token")
    AF.request(url, method: .post, headers: headers)
      .validate(statusCode: 200..<300)
      .responseJSON { responseJSON in
        switch responseJSON.result {
        case .success(let json as [String: AnyObject]) where json["secret"] is String:
          completion((json["secret"] as! String), nil)
        case .success,
          .failure where responseJSON.response?.statusCode == 402:
          let description =
            responseJSON.data.flatMap({ String(data: $0, encoding: .utf8) })
            ?? "Failed to decode connection token"
          let error = NSError(
            domain: "example",
            code: 1,
            userInfo: [
              NSLocalizedDescriptionKey: description
            ])
          completion(nil, error)
        case .failure(let error):
          completion(nil, error)
        }
      }
  }

  // MARK: Endpoints for App

  /// Create PaymentIntent using https://github.com/stripe/example-terminal-backend
  ///
  /// - Parameters:
  ///   - params: parameters for PaymentIntent creation
  ///   - completion: called with result: either PaymentIntent client_secret, or the error
  func createPaymentIntent(
    _ params: PaymentIntentParameters, completion: @escaping (Swift.Result<String, Error>) -> Void
  ) {
    let url = self.baseURL.appendingPathComponent("create_payment_intent")

    var cardPresent: Parameters = [:]

    let requestExtendedAuth = params.paymentMethodOptionsParameters.cardPresentParameters
      .requestExtendedAuthorization
    if requestExtendedAuth {
      cardPresent["request_extended_authorization"] = String(requestExtendedAuth)
    }

    let requestIncrementalAuth = params.paymentMethodOptionsParameters.cardPresentParameters
      .requestIncrementalAuthorizationSupport
    if requestIncrementalAuth {
      cardPresent["request_incremental_authorization_support"] = String(requestIncrementalAuth)
    }

    AF.request(
      url, method: .post,
      parameters: [
        "amount": params.amount,
        "currency": params.currency,
        "capture_method": params.captureMethod.toString(),
        "description": params.statementDescriptor ?? "Example PaymentIntent",
        "payment_method_types": params.paymentMethodTypes,
        "payment_method_options": [
          "card_present": cardPresent
        ],
      ]
    )
    .validate(statusCode: 200..<300)
    .responseJSON { responseJSON in
      switch responseJSON.result {
      case .success(let json as [String: AnyObject]):
        if let secret = json["secret"] as? String {
          completion(.success(secret))
          return
        }
        fallthrough
      case .success,
        .failure where responseJSON.response?.statusCode == 402:
        let description =
          responseJSON.data.flatMap({ String(data: $0, encoding: .utf8) })
          ?? "Failed to create PaymentIntent"
        let error = NSError(
          domain: "example",
          code: 4,
          userInfo: [
            NSLocalizedDescriptionKey: description
          ])
        completion(.failure(error))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func capturePaymentIntent(_ paymentIntentId: String, completion: @escaping ErrorCompletionBlock) {
    let headers: HTTPHeaders = [
      "Authorization": "Token " + (currentToken ?? ""),
      "Accept": "application/json",
    ]
    let url = self.baseURL.appendingPathComponent("minting/capture_payment_intent")
    AF.request(
      url, method: .post, parameters: ["payment_intent_id": paymentIntentId], headers: headers
    )
    .validate(statusCode: 200..<300)
    .responseString { response in
      switch response.result {
      case .success:
        completion(nil)
      case .failure where response.response?.statusCode == 402:
        let description =
          response.data.flatMap({ String(data: $0, encoding: .utf8) })
          ?? "Failed to capture PaymentIntent"
        let error = NSError(
          domain: "example",
          code: 2,
          userInfo: [
            NSLocalizedDescriptionKey: description
          ])
        completion(error)
      case .failure(let error):
        completion(error)
      }
    }
  }

  func createSetupIntent(
    _ params: SetupIntentParameters, completion: @escaping (Swift.Result<String, Error>) -> Void
  ) {
    var alamofireParams: Parameters = [
      "payment_method_types": ["card_present"]
    ]

    if let customer = params.customer {
      alamofireParams["customer"] = customer
    }

    if let onBehalfOf = params.onBehalfOf {
      alamofireParams["on_behalf_of"] = onBehalfOf
    }

    if let description = params.stripeDescription {
      alamofireParams["description"] = description
    }

    let url = self.baseURL.appendingPathComponent("create_setup_intent")
    AF.request(
      url, method: .post,
      parameters: alamofireParams
    )
    .validate(statusCode: 200..<300)
    .responseJSON { responseJSON in
      switch responseJSON.result {
      case .success(let json as [String: AnyObject]):
        if let secret = json["secret"] as? String {
          completion(.success(secret))
          return
        }
        fallthrough
      case .success,
        .failure where responseJSON.response?.statusCode == 402:
        let description =
          responseJSON.data.flatMap({ String(data: $0, encoding: .utf8) })
          ?? "Failed to create SetupIntent"
        let error = NSError(
          domain: "example",
          code: 4,
          userInfo: [
            NSLocalizedDescriptionKey: description
          ])
        completion(.failure(error))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func attachPaymentMethod(
    _ paymentMethodId: String, completion: @escaping ([String: AnyObject]?, Error?) -> Void
  ) {
    let url = self.baseURL.appendingPathComponent("attach_payment_method_to_customer")
    AF.request(
      url, method: .post,
      parameters: ["payment_method_id": paymentMethodId]
    )
    .validate(statusCode: 200..<300)
    .responseJSON { responseJSON in
      switch responseJSON.result {
      case .success(let json as [String: AnyObject]):
        completion(json, nil)
      case .success,
        .failure where responseJSON.response?.statusCode == 402:
        let description =
          responseJSON.data.flatMap({ String(data: $0, encoding: .utf8) })
          ?? "Failed to decode PaymentMethod & Customer"
        let error = NSError(
          domain: "example",
          code: 3,
          userInfo: [
            NSLocalizedDescriptionKey: description
          ])
        completion(nil, error)
      case .failure(let error):
        completion(nil, error)
      }
    }
  }

  func registerReader(
    withCode registrationCode: String, label: String,
    completion: @escaping ([String: AnyObject]?, Error?) -> Void
  ) {
    let locationId = "tml_FAcFQ99ExLcpsf"
    let url = self.baseURL.appendingPathComponent("register_reader")
    AF.request(
      url, method: .post,
      parameters: [
        "label": label,
        "registration_code": registrationCode,
        "location": locationId,
      ]
    )
    .validate(statusCode: 200..<300)
    .responseJSON { responseJSON in
      switch responseJSON.result {
      case .success(let json as [String: AnyObject]):
        completion(json, nil)
      case .success,
        .failure where responseJSON.response?.statusCode == 402:
        let description =
          responseJSON.data.flatMap({ String(data: $0, encoding: .utf8) })
          ?? "Failed to decode registered reader"
        let error = NSError(
          domain: "example",
          code: 3,
          userInfo: [
            NSLocalizedDescriptionKey: description
          ])
        completion(nil, error)
      case .failure(let error):
        completion(nil, error)
      }
    }
  }
}
