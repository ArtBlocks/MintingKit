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
    Group {
      if projects.isEmpty {
        ProgressView().onAppear(perform: fetchProjects)
      } else {
        projectList
      }
    }
  }

  private var projectList: some View {
    List {
      projectSection
      paymentSection
    }
    .sheet(isPresented: $showTerminal) {
      stripeTerminalView
    }
    .onAppear {
      AppDelegate.apiClient?.currentToken = self.currentToken
    }
  }

  private var projectSection: some View {
    Section {
      ForEach(projects, id: \.id) { project in
        Button(project.title) {
          withAnimation {
            self.currentProject = project
            self.currentScreen = .minting
          }
        }
      }
    }
  }

  private var paymentSection: some View {
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
  }

  private var stripeTerminalView: some View {
    RootViewControllerView().toolbar {
      ToolbarItem(placement: .navigation) {
        Button("Done") {
          showTerminal = false
        }
      }
    }
    .navigationBarTitle("Stripe Terminal")
  }

  private func fetchProjects() {
    guard let token = currentToken else { return }

    let headers: HTTPHeaders = [
      "Authorization": "Token " + token,
      "Accept": "application/json",
    ]

    AF.request("https://minting-api.artblocks.io/project", method: .get, headers: headers)
      .validate().responseJSON { response in
        handleResponse(response)
      }
  }

  private func handleResponse(_ response: AFDataResponse<Any>) {
    switch response.result {
    case .success(let value):
      parseJSON(value)
    case .failure:
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: fetchProjects)
    }
  }

  private func parseJSON(_ value: Any) {
    let json = JSON(value)["results"].arrayValue
    let newProjects = json.map { project in
      Project(
        id: project["id"].stringValue,
        title: project["title"].stringValue,
        priceAmountCents: project["price_amount_cents"].intValue,
        paymentEthAddress: project["payment_details"]["eth_address"].string
      )
    }
    updateProjects(newProjects)
  }

  private func updateProjects(_ newProjects: [Project]) {
    if AppState.shared.intentOpenProject != "" {
      if let project = newProjects.first(where: {
        $0.title.lowercased() == AppState.shared.intentOpenProject.lowercased()
      }) {
        withAnimation {
          self.currentProject = project
          self.currentScreen = .minting
        }
        return
      }
    }
    projects.append(contentsOf: newProjects)
  }
}

struct ProjectsView_Previews: PreviewProvider {
  static var previews: some View {
    ProjectsView(
      currentToken: .constant(nil),
      currentProject: .constant(nil),
      currentScreen: .constant(.projects)
    )
  }
}
