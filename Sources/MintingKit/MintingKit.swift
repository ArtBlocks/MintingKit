import Alamofire
import BetterSafariView
import KeychainSwift
import LocalAuthentication
import SwiftUI

let API_BASE_URL_STRING = "https://minting-api.artblocks.io"
let ENDPOINT_URL = URL(string: API_BASE_URL_STRING)!
let RENDER_BLOCK_CONFIRMATIONS = 3  // number of block confirmations before rendering

/// Enumerates errors specific to the state of the MintingKit SDK
public enum MKError: Error {
  /// Thrown when an API URL is incorrectly configured
  case malformedURL(String)

  /// Thrown when an ENS name is not found
  case ensNotFound(String)

  /// Thrown when an error occurs during token minting
  case tokenError(String)

  /// Thrown when a websocket connection fails
  case socketError(String)
}

/// Data structure describing a mintable Art Blocks project
public struct MKProject: Codable {
  /// The string ID of the project available for minting
  let id: String

  /// The string title of the project available for minting
  let title: String
}

/// Provides a decodable structure for the project list API JSON response
private struct ProjectListResults: Decodable {
  /// The list of projects returned from the API
  let results: [MKProject]
}

/// Provides a decodable structure for the ENS lookup API JSON response
private struct ENSLookupResult: Decodable {
  /// The ETH address corresponding to the ENS name
  let ethAddress: String?
}

/// Provides a decodable structure for the "is mintable" API JSON response
private struct IsMintableResult: Decodable {
  /// Whether or not the project can be minted
  let mintable: Bool

  /// A status message indicating the current state of the project
  let message: String
}

/// Data structure describing a single minting transaction and its current status
public struct MKMinting: Codable {
  /// The primary key ID of the mint
  let id: String

  /// The number of block confirmations for the minting transaction
  var blockConfirmations: Int?

  /// The shareable URL for the artwork that the user can send to others
  var shareUrl: String?

  /// The generator URL that can be placed in an iframe or WebView to display the artwork
  var embedUrl: String?

  /// Whether or not the minting fee has been paid in fiat
  var isPaid: Bool?
}

/**
 Provides an SDK for quickly deploying apps built on top of the Art Blocks Minting API.
 - Parameter authToken: The authentication token for the current user
 */
public struct MintingKit {
  /// The API token obtaiend for the currently-authenticated user
  let authToken: String

  /**
   Constructs HTTP heards for authentication and data type to make HTTP REST API calls.
   - Returns: A new HTTPHeaders object to be used in HTTP requests
   */
  private func buildHeaders() -> HTTPHeaders {
    return [
      "Authorization": "Token \(authToken)",
      "Accept": "application/json",
    ]
  }

  /**
   Retrieves a list of Art Blocks projects available to the currently authenticated machine.
   - Parameter onSuccess: The callback function to handle the retrieved array of MKProject objects
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func listProjects(
    onSuccess: @escaping ([MKProject]) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    AF.request(
      ENDPOINT_URL.appendingPathComponent("project"), method: .get, headers: buildHeaders()
    )
    .validate().responseDecodable(of: ProjectListResults.self) { response in
      switch response.result {
      case .success(let value):
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        onSuccess(value.results)
      case .failure(let error):
        onFailure(error)
      }
    }
  }

  /**
   Looks up the full Ethereum address for a provided ENS name.
   - Parameter ensName: The ENS name to look up e.g. artblocks.eth
   - Parameter onSuccess: The callback function to handle the retrieved Ethereum address string
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func ensLookup(
    ensName: String,
    onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    AF.request(
      ENDPOINT_URL.appendingPathComponent("wallet/ens?ens_name=\(ensName)"), method: .get,
      headers: buildHeaders()
    ).validate().responseDecodable(of: ENSLookupResult.self) { response in
      switch response.result {
      case .success(let value):
        if let ethAddress = value.ethAddress {
          onSuccess(ethAddress)
        } else {
          onFailure(MKError.ensNotFound("Unable to find ENS name: \(ensName)"))
        }
      case .failure(let error):
        onFailure(error)
      }
    }
  }

  /**
   Verifies that a project can be minted by the currently authenticated machine.
   - Parameter projectId: the full string ID of the project being minted
   - Parameter onSuccess: The callback function to handle the retrieved status of the project
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func checkIfMintable(
    projectId: String,
    onSuccess: @escaping (Bool, String) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    let headers: HTTPHeaders = [
      "Authorization": "Token " + authToken,
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        ENDPOINT_URL.appendingPathComponent("project/\(projectId)/mintable"), method: .get,
        headers: headers
      ).validate().responseDecodable(of: IsMintableResult.self) { response in
        switch response.result {
        case .success(let value):
          onSuccess(value.mintable, value.message)
        case .failure(let error):
          onFailure(error)
        }
      }
    }
  }

  /**
   Mint a project using the Art Blocks Minting API.
   - Parameter projectId: the full string ID of the project being minted
   - Parameter onSuccess: The callback function to handle the string ID of the new mint
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func mintProject(
    projectId: String, walletAddress: String,
    onSuccess: @escaping (String) -> Void,
    onFailure: @escaping (Error) -> Void
  ) {
    DispatchQueue.main.async {
      let headers: HTTPHeaders = [
        "Authorization": "Token " + authToken,
        "Accept": "application/json",
      ]
      let parameters: [String: String] = [
        "destination_wallet": walletAddress,
        "project": projectId,
      ]

      AF.request(
        ENDPOINT_URL.appendingPathComponent("minting"),
        method: .post, parameters: parameters, encoding: JSONEncoding.default,
        headers: headers
      ).validate().responseDecodable(of: MKMinting.self) { response in
        switch response.result {
        case .success(let value):
          onSuccess(value.id)
        case .failure(let error):
          onFailure(error)
        }
      }
    }
  }

  public func onMintingUpdate(
    mintId: String,
    onUpdate: @escaping (MKMinting) -> Void,
    onError: @escaping (Error) -> Void
  ) {
    guard var urlComponents = URLComponents(url: ENDPOINT_URL, resolvingAgainstBaseURL: false)
    else {
      // this error is typically unreachable - something went wrong with the Swift internal URL construction API
      onError(MKError.malformedURL("Unable to construct URL for API calls."))
      return
    }
    urlComponents.scheme = "ws"  // use a websocket connection scheme instead of https
    guard let url = try? urlComponents.asURL().appendingPathComponent("ws/minting/\(mintId)") else {
      // this error is typically unreachable - something went wrong with the Swift internal URL construction API
      onError(MKError.malformedURL("Unable to construct URL for API calls."))
      return
    }
    var request = URLRequest(url: url)
    let session = URLSession(configuration: .default)
    let socket = session.webSocketTask(with: request)
    socket.resume()
    func onMintingSocketReceive(result: Result<Foundation.URLSessionWebSocketTask.Message, Error>) {
      switch result {
      case .failure(let error):
        onError(error)
      case .success(let message):
        switch message {
        case .string(let messageString):
          print(messageString)
        case .data(let data):
          print(data.description)
        default:
          onError(MKError.socketError("Unknown type received from WebSocket"))
        }
      }
    }
    socket.receive(completionHandler: onMintingSocketReceive)
  }

  /**
   Retrieves the latest transaction information for a previous or ongoing minting.
   - Parameter mintId: The string ID of the minting to retrieve
   - Parameter onSuccess: The callback function to handle the retrieved MKMinting object
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func retrieveMinting(
    mintId: String,
    onSuccess: @escaping (MKMinting) -> Void,
    onFailure: @escaping (Error) -> Void
  ) {
    let headers: HTTPHeaders = [
      "Authorization": "Token \(authToken)",
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        ENDPOINT_URL.appendingPathComponent("minting/\(mintId)"), method: .get, headers: headers
      ).validate().responseDecodable(of: MKMinting.self) {
        response in
        switch response.result {
        case .success(let value):
          onSuccess(value)
        case .failure(let error):
          onFailure(error)
        }
      }
    }
  }
}

/// A login button that signs in the current iOS user into the Minting API.
public struct MintingLoginButton<Label: View>: View {
  @State private var startingWebAuthenticationSession = false
  let keychain = KeychainSwift()
  let label: Label
  let onSuccess: (String) -> Void
  let onFailure: (Error) -> Void

  init(
    onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void,
    @ViewBuilder label: () -> Label
  ) {
    self.label = label()
    self.onSuccess = onSuccess
    self.onFailure = onFailure
  }

  public var body: some View {
    Button(action: { startingWebAuthenticationSession = true }) {
      label
    }.onAppear {
      DispatchQueue.main.async {
        guard let lastOpened = UserDefaults.standard.object(forKey: "LastOpened") as? Date else {
          return
        }
        guard
          let elapsed = Calendar.current.dateComponents([.day], from: lastOpened, to: Date()).day
        else {
          return
        }
        if elapsed >= 6 {
          return
        }
        if let t = keychain.get("authToken") {
          let context = LAContext()
          var error: NSError?

          // check whether biometric authentication is possible
          if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(
              .deviceOwnerAuthenticationWithBiometrics, localizedReason: reason
            ) { success, authenticationError in
              // authentication has now completed
              if success {
                onSuccess(t)
              } else {
                // there was a problem
              }
            }
          } else {
            // no biometrics
          }
        }
      }
    }
    .webAuthenticationSession(isPresented: $startingWebAuthenticationSession) {
      WebAuthenticationSession(
        url: ENDPOINT_URL.appendingPathComponent("app/?appauth=true"),
        callbackURLScheme: "txlessauth"
      ) { callbackURL, error in
        if let t = callbackURL?.host {
          DispatchQueue.main.async {
            keychain.set(t, forKey: "authToken")
            UserDefaults.standard.set(Date(), forKey: "LastOpened")
          }
          onSuccess(t)
        } else if let error = error {
          onFailure(error)
        } else {
          onFailure(MKError.tokenError("Unable to retrieve token from login screen."))
        }
      }
    }
  }
}
