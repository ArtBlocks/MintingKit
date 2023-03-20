//
//  ProjectsView.swift
//  TXLess Mint
//
//  Created by Shantanu Bala on 3/17/22.
//

import Alamofire
import SwiftUI
import SwiftyJSON

struct Project {
  let id: String
  let title: String
  let priceAmountCents: Int
  var paymentEthAddress: String?
}

struct ProjectsView: View {
  @Binding var currentToken: String?
  @Binding var currentProject: Project?
  @Binding var currentScreen: ScreenID
  @State var errorMessage = ""
  @State var projects = [Project]()
  @State private var showTerminal = false

  var body: some View {
    if projects.count == 0 {
      ProgressView().onAppear {
        fetchProjects()
      }
    } else {
      List {
        Section {
          ForEach(
            projects, id: \.id
          ) { project in
            Button(project.title) {
              withAnimation {
                self.currentProject = project
                self.currentScreen = .minting
              }
            }
          }
        }

        Section("Payments") {
          Button {
            showTerminal = true
          } label: {
            HStack {
              Image(systemName: "creditcard")
              Text("Stripe Terminal")
            }
          }

        }

      }.sheet(isPresented: $showTerminal) {
        RootViewControllerView().toolbar {
          ToolbarItem(placement: .navigation) {
            Button("Done") {
              showTerminal = false
            }
          }
        }.navigationBarTitle("Stripe Terminal")
      }.onAppear {
        AppDelegate.apiClient?.currentToken = self.currentToken
      }
    }
  }

  func fetchProjects() {
    let headers: HTTPHeaders = [
      "Authorization": "Token " + currentToken!,
      "Accept": "application/json",
    ]

    DispatchQueue.main.async {
      AF.request("https://minting-api.artblocks.io/project", method: .get, headers: headers)
        .validate().responseJSON { response in
          switch response.result {
          case .success(let value):
            let json = JSON(value)["results"].arrayValue
            projects.append(
              contentsOf: json.map { project in
                return Project(
                  id: project["id"].stringValue, title: project["title"].stringValue,
                  priceAmountCents: project["price_amount_cents"].intValue,
                  paymentEthAddress: project["payment_details"]["eth_address"].string)
              })
          case .failure(_):
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
              fetchProjects()
            }
          }
        }
    }
  }
}

struct ProjectsView_Previews: PreviewProvider {
  static var previews: some View {
    ProjectsView(
      currentToken: .constant(nil), currentProject: .constant(nil),
      currentScreen: .constant(.projects))
  }
}
