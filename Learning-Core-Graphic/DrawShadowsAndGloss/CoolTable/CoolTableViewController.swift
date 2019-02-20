/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class CoolTableViewController: UITableViewController {
  let thingsToLearn = ["Drawing Rects", "Drawing Gradients", "Drawing Arcs"]
  let thingsLearned = ["Table Views", "UIKit", "Swift"]
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return section == 0 ? thingsToLearn.count : thingsLearned.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    if cell.backgroundView?.isKind(of: CustomCellBackground.self) != true {
      cell.backgroundView = CustomCellBackground()
    }
    
    if cell.selectedBackgroundView?.isKind(of: CustomCellBackground.self) != true {
      cell.selectedBackgroundView = CustomCellBackground()
    }
    
    cell.textLabel?.text = indexPath.section == 0 ? thingsToLearn[indexPath.row] : thingsLearned[indexPath.row]
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let customHeaderView = CustomHeader.loadViewFromNib() else {return nil}
    customHeaderView.titleLabel.text = self.tableView(tableView, titleForHeaderInSection: section)
    if section == 1 {
      customHeaderView.lightColor = UIColor(
        red: 147/255.0,
        green: 105/255.0,
        blue: 216/255.0,
        alpha: 1)
      customHeaderView.darkColor = UIColor(
        red: 72/255.0,
        green: 22/255.0,
        blue: 137/255.0,
        alpha: 1)
    }
    return customHeaderView
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return section == 0 ? "Things We'll Learn" : "Things Already Covered"
  }
}
