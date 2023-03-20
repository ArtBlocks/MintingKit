//
//  MintingView.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 3/17/22.
//

import AVFoundation
import Alamofire
import CodeScanner
import CoreImage
import QRCode
import SwiftUI
import SwiftyJSON
import web3

enum ActiveSheet: Identifiable {
  case confirmation, minting, paymentCode

  var id: Int {
    hashValue
  }
}

struct LandscapeVHStack<Content: View>: View {
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

  var content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

  var body: some View {
    if horizontalSizeClass == .regular {
      HStack(alignment: .top, spacing: -16) {
        content()
      }
    } else {
      VStack(alignment: .leading) {
        content()
      }
    }
  }
}

enum SheetID: Identifiable {
  var id: Self {
    return self
  }

  case camera
  case payments
}

struct MintingView: View {
  @Binding var currentToken: String?
  @Binding var currentScreen: ScreenID
  @Binding var currentProject: Project?
  @State private var activeSheet: ActiveSheet? = nil
  @State private var currentSheet: SheetID? = nil
  @State private var isLoading = false
  @State private var scannedCode: String = ""
  @State private var embedUrl: String? = nil
  @State private var shareUrl: String? = nil
  @State private var mintingUrl: String? = nil
  @State private var blockConfirmations = 0
  @State private var ensName: String = ""
  @State private var ensLoading = false
  @State private var previousEmbedUrl: String? = nil
  @State private var previousMetadata: JSON? = nil
  @State private var errorMessage = ""
  @State private var isMintable = false
  @State private var mintableMessage = ""
  @FocusState private var ensFieldIsFocused: Bool
  private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }

  @Environment(\.scenePhase) var scenePhase

  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        if scannedCode == "" && !isLoading {
          LandscapeVHStack {

            VStack(alignment: .leading) {
              VStack(alignment: .leading) {
                Text("Mint to your wallet").font(.headline)
                TextField(
                  "yourname.eth",
                  text: $ensName
                )
                .focused($ensFieldIsFocused)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                Button {
                  let sanitizedInput = ensName.trimmingCharacters(in: .whitespacesAndNewlines)
                  if sanitizedInput.web3.isAddress {
                    self.scannedCode = sanitizedInput
                    activeSheet = .confirmation
                  } else {
                    lookupENSName()
                  }
                } label: {
                  HStack {
                    if ensLoading {
                      ProgressView()
                    } else {
                      Image(systemName: "network")
                      Text("Use ENS/ETH address")
                    }
                  }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(.ultraThickMaterial)
                .cornerRadius(16)
                .overlay(
                  RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary, lineWidth: 3)
                )
              }.padding(.horizontal).padding(.top)
                .textFieldStyle(RoundedBorderTextFieldStyle())

              VStack(alignment: .leading) {
                Button {
                  activeSheet = nil
                  currentSheet = .camera
                } label: {
                  HStack {
                    Image(systemName: "qrcode")
                    Text("Scan ETH address")
                  }
                }.padding(8)
                  .frame(maxWidth: .infinity)
                  .background(.ultraThickMaterial)
                  .cornerRadius(16)
                  .overlay(
                    RoundedRectangle(cornerRadius: 16)
                      .stroke(Color.primary, lineWidth: 3)
                  )

              }.padding()

              if self.currentProject?.paymentEthAddress != nil {
                VStack(alignment: .leading) {
                  Divider()
                  Button {
                    activeSheet = .paymentCode
                  } label: {
                    HStack {
                      Image(systemName: "link")
                      Text("Pay with ETH")
                    }
                  }.padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThickMaterial)
                    .cornerRadius(16)
                    .overlay(
                      RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary, lineWidth: 3)
                    )
                    .padding()

                }
              }
            }.background(.regularMaterial).cornerRadius(16).padding()

            VStack(alignment: .leading) {
              GeometryReader { geo in
                if previousEmbedUrl != nil {
                  VStack(alignment: .leading) {
                    MintingEmbedView(url: previousEmbedUrl!).frame(
                      width: geo.size.width, height: geo.size.width)
                    VStack(alignment: .leading) {
                      Text((currentProject?.title ?? "Untitled")).font(.headline)
                      if previousMetadata != nil {
                        Text(previousMetadata!["artist"].stringValue).font(.caption2)
                      }
                      Text(
                        "Token #"
                          + NSString(
                            string: previousEmbedUrl!.replacingOccurrences(
                              of: "?render=true", with: "")
                          ).lastPathComponent
                          + (previousMetadata == nil
                            ? "" : " of " + previousMetadata!["series"].stringValue)
                      ).font(.subheadline)
                    }
                  }
                }
              }.padding()
            }
          }.onChange(of: scenePhase) { newPhase in
            /*if newPhase != .active {
             AppState.shared.sessionID = UUID()
             }*/
          }
        } else {

          VStack {
            if self.errorMessage != "" {
              VStack {
                Text(self.errorMessage)
                Text("Please restart the app and try again.")
              }.padding().background(.ultraThinMaterial).cornerRadius(8).padding()

            } else if activeSheet != nil {
              EmptyView()
            } else {
              ZStack(alignment: .center) {
                BlockLoadingView(progress: blockConfirmations).opacity(
                  0.25 + (Double(blockConfirmations) * 0.125)
                ).frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(String(blockConfirmations) + " block confirmation(s)...").font(
                  .system(.headline)
                ).padding().background(.ultraThinMaterial).cornerRadius(8)

              }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
          }
        }
      }
      .onAppear(perform: loadLastToken)
      .sheet(item: $currentSheet) { sheet in
        if sheet == .camera {
          CodeScannerView(
            codeTypes: [.qr], showViewfinder: true,
            simulatedData: "ethereum:0x2AB205962F213DDc525B09B23c4C468B6910DA15",
            videoCaptureDevice: idiom == .pad
              ? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
              : AVCaptureDevice.default(for: .video)
          ) { response in
            if case let .success(result) = response {
              scannedCode =
                result.string.replacingOccurrences(of: "ethereum:", with: "").components(
                  separatedBy: "@")[0]
              currentSheet = nil
              activeSheet = .confirmation
            }
          }
        } else if sheet == .payments {

        }
      }
      .fullScreenCover(item: $activeSheet) { item in
        switch item {
        case .minting:
          NavigationView {
            GeometryReader { geo in
              MintingEmbedView(url: embedUrl!).frame(width: geo.size.width, height: geo.size.height)
                .modifier(
                  ImageModifier(contentSize: CGSize(width: geo.size.width, height: geo.size.height))
                ).onAppear {
                  Haptics.shared.notify(.success)
                }
            }.toolbar {
              ToolbarItem(placement: .navigation) {
                Button("Done") {
                  DispatchQueue.main.async {
                    withAnimation {
                      self.previousEmbedUrl = self.embedUrl
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
                    }
                  }
                }
              }
              ToolbarItem(placement: .navigationBarTrailing) {
                if let url = URL(string: shareUrl ?? "") {
                  if #available(iOS 16.0, *) {
                    ShareLink(item: url)
                  } else {
                    // Fallback on earlier versions
                  }
                }
              }
            }
          }.interactiveDismissDisabled()
        case .confirmation:
          ConfirmationView(
            currentToken: $currentToken, currentScreen: $currentScreen,
            currentProject: $currentProject, activeSheet: $activeSheet, isLoading: $isLoading,
            scannedCode: $scannedCode, shareUrl: $shareUrl, embedUrl: $embedUrl,
            mintingUrl: $mintingUrl,
            blockConfirmations: $blockConfirmations, ensName: $ensName,
            previousEmbedUrl: $previousEmbedUrl, previousMetadata: $previousMetadata,
            errorMessage: $errorMessage, isMintable: $isMintable,
            mintableMessage: $mintableMessage
          ).interactiveDismissDisabled()
        case .paymentCode:
          if let e = self.currentProject?.paymentEthAddress {
            if let qrData = ("ethereum:" + String(e)).data(using: .utf8) {
              NavigationView {
                VStack {
                  QRCodeUI(
                    data: qrData)
                }.toolbar {
                  ToolbarItem(placement: .navigation) {
                    Button("Done") {
                      DispatchQueue.main.async {
                        self.activeSheet = nil
                      }
                    }
                  }
                }
              }.interactiveDismissDisabled()
            }
          }
        }
      }
    }
  }

  func loadLastToken() {
    guard let currentToken = currentToken else {
      return
    }
    let headers: HTTPHeaders = [
      "Authorization": "Token " + currentToken,
      "Accept": "application/json",
    ]
    print("Loading last token...")
    DispatchQueue.main.async {
      if previousEmbedUrl == nil {
        AF.request(
          "https://minting-api.artblocks.io/minting", method: .get, headers: headers
        ).validate().responseJSON { response in
          switch response.result {
          case .success(let value):
            let json = JSON(value)
            for result in json["results"].arrayValue {
              if !result["project"].stringValue.contains(self.currentProject!.id) {
                continue
              }
              if let url = result["embed_url"].string {
                previousEmbedUrl = url
                print(url)
                previousMetadata = result["metadata"]
                break
              }
            }
          case .failure(_):
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
              loadLastToken()
            }
          }
        }
      }
    }
  }

  func lookupENSName() {
    if ensName == "" {
      return
    }
    guard let currentToken = currentToken else {
      return
    }
    let headers: HTTPHeaders = [
      "Authorization": "Token " + currentToken,
      "Accept": "application/json",
    ]
    DispatchQueue.main.async {
      self.ensLoading = true
      AF.request(
        "https://minting-api.artblocks.io/wallet/ens?ens_name="
          + ensName, method: .get, headers: headers
      ).validate().responseJSON { response in
        self.ensLoading = false
        switch response.result {
        case .success(let value):
          let json = JSON(value)
          if let ethAddress = json["eth_address"].string {
            self.scannedCode = ethAddress
            activeSheet = .confirmation
          } else {
            self.scannedCode = ""
            self.mintableMessage = "Unable to find ENS name."
            self.isMintable = false
            activeSheet = .confirmation
          }
        case .failure(let error):
          print(error)
          self.scannedCode = ""
          self.mintableMessage = "ENS lookup failed."
          self.isMintable = false
          activeSheet = .confirmation
        }
      }
    }
  }
}

struct ScanEthAddressView_Previews: PreviewProvider {
  static var previews: some View {
    MintingView(
      currentToken: .constant("fake"), currentScreen: .constant(.minting),
      currentProject: .constant(Project(id: "fakeid", title: "Test Project", priceAmountCents: 0)))
  }
}
