import StripeTerminal
import SwiftUI
import UIKit

class RootViewController: LargeTitleNavigationController {
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let vc = ReaderViewController()
    self.pushViewController(vc, animated: false)
  }

}

struct RootViewControllerView: UIViewControllerRepresentable {
  typealias UIViewControllerType = ReaderViewController
  func makeUIViewController(context: Context) -> ReaderViewController {
    let vc = ReaderViewController()
    // Do some configurations here if needed.
    return vc
  }

  func updateUIViewController(_ uiViewController: ReaderViewController, context: Context) {
    // Updates the state of the specified view controller with new information from SwiftUI.
  }
}
