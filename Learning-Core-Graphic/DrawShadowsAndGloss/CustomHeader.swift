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


class CustomHeader: UIView {

  @IBInspectable var coloredBoxHeight: CGFloat = 40
  @IBOutlet weak var titleLabel: UILabel!
  
  var lightColor = UIColor(red: 105/255.0, green: 179/255.0, blue: 216/255.0, alpha: 1)
  var darkColor = UIColor(red: 21/255.0, green: 92/255.0, blue: 136/255.0, alpha: 1)

  override func draw(_ rect: CGRect) {
    // 1:
    var coloredBoxRect = bounds
    coloredBoxRect.size.height = coloredBoxHeight
    
    var paperRect = bounds
    paperRect.origin.y += coloredBoxHeight
    paperRect.size.height = bounds.height - coloredBoxHeight
    
    // 2:
    let context = UIGraphicsGetCurrentContext()!
    let shadowColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.5)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 2), blur: 3.0, color: shadowColor.cgColor)
    context.setFillColor(lightColor.cgColor)
    context.fill(coloredBoxRect)
    context.restoreGState()
    
    context.drawGlossAndGradient(
      rect: coloredBoxRect,
      startColor: lightColor,
      endColor: darkColor)
    
    context.setStrokeColor(darkColor.cgColor)
    context.setLineWidth(1)
    context.stroke(coloredBoxRect.rectFor1PxStroke())
  }

  
  class func loadViewFromNib()->CustomHeader? {
    let bundle = Bundle.main
    let nib = UINib(nibName: "CustomHeader", bundle: bundle)
    guard let view = nib.instantiate(withOwner: CustomHeader())
      .first as? CustomHeader else {
      return nil
    }
    return view
  }

}
