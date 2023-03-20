import Static
import UIKit

/// Same as Static.Value1Cell, but supports wrapping in the text label if needed.
class Value1MultilineCell: UITableViewCell, Cell {
  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    self.textLabel?.numberOfLines = 0
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
