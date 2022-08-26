import Alamofire
import BetterSafariView
import KeychainSwift
import LocalAuthentication
import SwiftUI
import SwiftyJSON

private enum LoginError: Error {
  case tokenError(String)
}

private enum ENSError: Error {
  case ensNotFound(String)
}

public struct ABProject {
  let id: String
  let title: String
}

public struct ABProjectMint {
  var blockConfirmations: Int
  var shareUrl: String?
  var embedUrl: String?
  var receipt: JSON?
  var isPaid: Bool?
}

public struct MintingKit {
  let token: String
  let endpoint = URL(string: "https://minting-api.artblocks.io")!

  private func buildHeaders() -> HTTPHeaders {
    return [
      "Authorization": "Token \(token)",
      "Accept": "application/json",
    ]
  }

  public func listProjects(
    onSuccess: @escaping ([ABProject]) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    AF.request(endpoint.appendingPathComponent("project"), method: .get, headers: buildHeaders())
      .validate().responseJSON { response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)["results"].arrayValue
          let projects = json.map { project in
            return ABProject(id: project["id"].stringValue, title: project["title"].stringValue)
          }
          onSuccess(projects)
        case .failure(let error):
          onFailure(error)
        }
      }
  }

  public func ensLookup(
    ensName: String,
    onSuccess: @escaping (String) -> Void, onFailure: @escaping (Error) -> Void
  ) {
    AF.request(
      endpoint.appendingPathComponent("wallet/ens?ens_name=\(ensName)"), method: .get,
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
        "https://minting-api.artblocks.io/project/\(projectId)/mintable", method: .get,
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
        "https://minting-api.artblocks.io/minting",
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

  public func retrieveMint(
    mintId: String,
    onSuccess: @escaping (ABProjectMint) -> Void,
    onFailure: @escaping (Error) -> Void
  ) {
    let headers: HTTPHeaders = [
      "Authorization": "Token \(token)",
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        "https://minting-api.artblocks.io/minting/\(mintId)", method: .get, headers: headers
      ).validate().responseJSON {
        response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          var mint = ABProjectMint(blockConfirmations: 0)
          if let confirmations = json["block_confirmations"].int {
            mint.blockConfirmations = confirmations
          }
          if let shareUrlString = json["share_url"].string {
            mint.shareUrl = shareUrlString
          }
          if let urlString = json["embed_url"].string {
            if mint.blockConfirmations >= 3 {
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
        url: URL(string: "https://minting-api.artblocks.io/app/?appauth=true")!,
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
