//
//  MintingEmbedView.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 3/18/22.
//

import Alamofire
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
  var url: URL
  @Binding var workState: WorkState

  enum WorkState: String {
    case initial
    case done
    case working
    case errorOccurred
  }

  func loadWebPageAndRetry(_ uiView: WKWebView) {
    AF.request(url, method: .get).validate().responseString { response in
      switch response.result {
      case .success(let value):
        DispatchQueue.main.async {
          uiView.loadHTMLString(value, baseURL: url)
        }
      case .failure(_):
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          loadWebPageAndRetry(uiView)
        }
      }
    }

  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.contentMode = .scaleAspectFit
    webView.scrollView.isScrollEnabled = false
    webView.navigationDelegate = context.coordinator
    webView.isOpaque = false
    webView.backgroundColor = UIColor.clear
    webView.scrollView.backgroundColor = UIColor.clear
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    switch self.workState {
    case .initial:
      self.loadWebPageAndRetry(uiView)
    default:
      break
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, WKNavigationDelegate {
    var parent: WebView

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      self.parent.workState = .working
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      self.parent.workState = .errorOccurred
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      self.parent.workState = .done
    }

    init(_ parent: WebView) {
      self.parent = parent
    }
  }
}

extension ProgressView {
  @ViewBuilder func isHidden(_ isHidden: Bool) -> some View {
    if isHidden {
      self.hidden()
    } else {
      self
    }
  }
}

struct MintingEmbedView: View {
  let url: String
  @State var workState = WebView.WorkState.initial

  var body: some View {
    ZStack(alignment: .center) {
      WebView(url: URL(string: url)!, workState: $workState)
      ProgressView().isHidden(workState == .done)
    }
  }
}

struct MintingEmbedView_Previews: PreviewProvider {
  static var previews: some View {
    MintingEmbedView(
      url: "https://generator-staging.artblocks.io/0x0583379345586d5219ca842c6ec463f8cdddbc84/16")
  }
}
