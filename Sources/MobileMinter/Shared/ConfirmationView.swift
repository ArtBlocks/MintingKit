//
//  ConfirmationView.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 7/1/22.
//

import Alamofire
import MintingKit
import StripeTerminal
import SwiftUI
import SwiftyJSON

struct ConfirmationView: View {
  @Environment(\.dismiss) var dismiss
  @Binding var currentToken: String?
  @Binding var currentScreen: ScreenID
  @Binding var currentProject: Project?
  @Binding var activeSheet: ActiveSheet?
  @Binding var isLoading: Bool
  @Binding var scannedCode: String
  @Binding var shareUrl: String?
  @Binding var embedUrl: String?
  @Binding var mintingUrl: String?
  @Binding var blockConfirmations: Int
  @Binding var ensName: String
  @Binding var previousEmbedUrl: String?
  @Binding var previousMetadata: JSON?
  @Binding var errorMessage: String
  @Binding var isMintable: Bool
  @Binding var mintableMessage: String

  @State private var isConfirmed = false
  @State private var paidWithCard = false

  var currencyFormatter: NumberFormatter {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.usesGroupingSeparator = true
    currencyFormatter.numberStyle = .currency
    currencyFormatter.locale = Locale.current
    return currencyFormatter
  }

  var currentPrice: String {
    let price = self.currentProject?.priceAmountCents ?? 0
    guard price != 0 else {
      return ""
    }
    let dollars = Double(price) / 100.0
    return currencyFormatter.string(from: NSNumber(value: dollars)) ?? ""
  }

  var body: some View {
    NavigationView {
      Group {
        if isConfirmed && (paidWithCard) {
          VStack {
            Spacer()
            Button(action: {
              dismiss()
              activeSheet = nil
              Haptics.shared.play(.heavy)
              startMinting()
            }) {
              Text("MINT")
                .font(.title)
                .fontWeight(.heavy)
                .frame(width: 300, height: 300)
                .background(.ultraThickMaterial)
                .clipShape(Circle())
                .overlay(
                  Circle()
                    .stroke(Color.primary, lineWidth: 3)
                )
                .shadow(color: Color.black, radius: 4.0)
                .transition(.scale)
            }
            Spacer()
          }
        } else if isConfirmed && Terminal.shared.connectedReader == nil {
          RootViewControllerView()
        } else if isConfirmed {
          PaymentViewControllerView(
            priceAmountCents: UInt(self.currentProject?.priceAmountCents ?? 0),
            action: {
              withAnimation {
                self.paidWithCard = true
              }
            })
        } else {
          VStack(alignment: .leading) {
            Text("Project: " + (currentProject?.title ?? "")).font(.headline).truncationMode(
              .middle
            ).multilineTextAlignment(.leading).lineLimit(1)
            if currentPrice != "" {
              Text(currentPrice).font(.subheadline)
                .multilineTextAlignment(.leading)
                .lineLimit(nil).frame(maxWidth: .infinity, alignment: .leading)
            }
            if scannedCode != "" {
              Text(scannedCode).font(.largeTitle)
                .multilineTextAlignment(.leading)
                .lineLimit(nil).frame(maxWidth: .infinity, alignment: .leading)
            }
            if self.mintableMessage != "" {
              Text(self.mintableMessage).multilineTextAlignment(.leading).padding(.vertical)
                .onAppear {
                  Haptics.shared.notify(.error)
                }
            }
            if isMintable {
              Button {
                withAnimation {
                  self.isConfirmed = true
                }
              } label: {

                HStack {
                  Image(systemName: "checkmark.circle")
                  Text("Confirm wallet address")
                }
              }.padding(8)
                .frame(maxWidth: .infinity)
                .background(.ultraThickMaterial)
                .cornerRadius(16)
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary, lineWidth: 3)
                )
                .padding(.vertical)
            } else if self.mintableMessage == "" {
              ZStack {
                ProgressView()
              }.frame(maxWidth: .infinity)
            }
            Spacer()
          }.padding().navigationTitle("Confirm \(currentPrice)")
        }
      }.onAppear(perform: checkIfMintable)
        .toolbar {
          ToolbarItem(placement: .navigation) {
            Button("Exit") {
              DispatchQueue.main.async {
                withAnimation {
                  self.embedUrl = nil
                  self.shareUrl = nil
                  self.activeSheet = nil
                  self.isLoading = false
                  self.scannedCode = ""
                  self.blockConfirmations = 0
                  self.ensName = ""
                  self.errorMessage = ""
                  self.isMintable = false
                  self.mintableMessage = ""
                  self.isConfirmed = false
                }
              }
            }
          }
        }
    }
  }

  func checkIfMintable() {
    guard let currentProject = self.currentProject else {
      return
    }
    if self.mintableMessage != "" {
      return
    }
    self.paidWithCard = self.currentProject?.priceAmountCents == 0
    let headers: HTTPHeaders = [
      "Authorization": "Token " + currentToken!,
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      AF.request(
        "https://minting-api.artblocks.io/project/" + currentProject.id + "/mintable", method: .get,
        headers: headers
      ).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          withAnimation {
            self.isMintable = json["mintable"].boolValue
            self.mintableMessage = json["message"].stringValue
          }
        case .failure(let error):
          withAnimation {
            self.isMintable = false
            self.mintableMessage = "Unable to verify project status."
          }
        }
      }
    }
  }

  func startMinting() {
    DispatchQueue.main.async {
      isLoading = true
      let headers: HTTPHeaders = [
        "Authorization": "Token " + currentToken!,
        "Accept": "application/json",
      ]
      let parameters: [String: String] = [
        "destination_wallet": scannedCode,
        "project": (currentProject?.id ?? ""),
      ]

      AF.request(
        "https://minting-api.artblocks.io/minting",
        method: .post, parameters: parameters, encoding: JSONEncoding.default,
        headers: headers
      ).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          mintingUrl = "https://minting-api.artblocks.io/minting/" + json["id"].stringValue
          pollProject()
        case .failure(_):
          if let statusCode = response.response?.statusCode {
            if statusCode == 403 {
              self.errorMessage = "This device does not yet have permission to mint."
            } else if 400 <= statusCode && statusCode <= 499 {
              self.errorMessage = "Please update your app to the latest version to use this API."
            } else {
              self.errorMessage =
                "We logged an error processing your request. Please check your minter contract and try again if minting failed."
            }
          } else {
            self.errorMessage = "Request failed. Please check your connection."
          }

        }
      }
    }
  }

  func pollProject() {
    if embedUrl != nil || mintingUrl == nil {
      return
    }
    let headers: HTTPHeaders = [
      "Authorization": "Token " + currentToken!,
      "Accept": "application/json",
    ]
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
      AF.request(mintingUrl!, method: .get, headers: headers).validate().responseJSON {
        response in
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          if let confirmations = json["block_confirmations"].int {
            withAnimation {
              blockConfirmations = confirmations
            }
          }
          if let shareUrlString = json["share_url"].string {
            withAnimation {
              shareUrl = shareUrlString
            }
          }
          if let urlString = json["embed_url"].string {
            if blockConfirmations >= 3 {
              withAnimation {
                embedUrl = urlString
                isLoading = false
                activeSheet = .minting
              }
            }
          }
          if let errors = json["receipt"]["errors"].string {
            withAnimation {
              self.errorMessage = errors
            }
          }
        case .failure(let error):
          print(error)
        }
        pollProject()
      }
    }
  }
}

/*
struct ConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationView()
    }
}
*/
