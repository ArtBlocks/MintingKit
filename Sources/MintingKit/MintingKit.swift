import Alamofire
import BetterSafariView
import KeychainSwift
import LocalAuthentication
import SwiftUI
import SwiftyJSON

let API_BASE_URL_STRING = "https://minting-api.artblocks.io"
let ENDPOINT_URL = URL(string: API_BASE_URL_STRING)!
let RENDER_BLOCK_CONFIRMATIONS = 3  // number of block confirmations before rendering

private enum LoginError: Error {
  case tokenError(String)
}

private enum ENSError: Error {
  case ensNotFound(String)
}

public struct MKProject {
  let id: String
  let title: String
}

public struct MKMinting {
  var blockConfirmations: Int?
  var shareUrl: String?
  var embedUrl: String?
  var receipt: JSON?
  var isPaid: Bool?
}

public struct MintingKit {
  let token: String

  /**
   Constructs HTTP heards for authentication and data type to make HTTP REST API calls.
   - Returns: A new HTTPHeaders object to be used in HTTP requests
  */
  private func buildHeaders() -> HTTPHeaders {
    return [
      "Authorization": "Token \(token)",
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
    .validate().responseJSON { response in
      switch response.result {
      case .success(let value):
        let json = JSON(value)["results"].arrayValue
        let projects = json.map { project in
          return MKProject(id: project["id"].stringValue, title: project["title"].stringValue)
        }
        onSuccess(projects)
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
    ).validate().responseJSON { response in
      switch response.result {
      case .success(let value):
        let json = JSON(value)
        if let ethAddress = json["eth_address"].string {
          onSuccess(ethAddress)
        } else {
          onFailure(ENSError.ensNotFound("Unable to find ENS name: \(ensName)"))
        }
      case .failure(let error):
        onFailure(error)
      }
    }
  }

  /**
   Verifies that a particular project can be minted by the currently authenticated machine.
   - Parameter projectId: the full string ID of the project being minted
   - Parameter onSuccess: The callback function to handle the retrieved status of the project
   - Parameter onFailure: The callback function to handle REST API errors
   */
  public func checkIfMintable(
    projectId: String,
    onSuccess: @escaping (Bool, String) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    let headers: HTTPHeaders = [
      "Authorization": "Token " + token,
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        ENDPOINT_URL.appendingPathComponent("project/\(projectId)/mintable"), method: .get,
        headers: headers
      ).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          onSuccess(json["mintable"].boolValue, json["message"].stringValue)
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
        "Authorization": "Token " + token,
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
      ).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          onSuccess(json["id"].stringValue)
        case .failure(let error):
          onFailure(error)
        }
      }
    }
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
      "Authorization": "Token \(token)",
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        ENDPOINT_URL.appendingPathComponent("minting/\(mintId)"), method: .get, headers: headers
      ).validate().responseJSON {
        response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          var mint = MKMinting()
          if let confirmations = json["block_confirmations"].int {
            mint.blockConfirmations = confirmations
          }
          if let shareUrlString = json["share_url"].string {
            mint.shareUrl = shareUrlString
          }
          if let urlString = json["embed_url"].string {
            if mint.blockConfirmations >= RENDER_BLOCK_CONFIRMATIONS {
              mint.embedUrl = urlString
            }
          }
          mint.receipt = json["receipt"]

          mint.isPaid = json["is_paid"].bool
          onSuccess(mint)
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
          onFailure(LoginError.tokenError("Unable to retrieve token from login screen."))
        }
      }
    }
  }
}
