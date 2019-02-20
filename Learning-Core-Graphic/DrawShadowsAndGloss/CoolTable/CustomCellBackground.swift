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

class CustomCellBackground: UIView {
  let lightGrayColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1)
  let separatorColor = UIColor(red: 208/255.0, green: 208/255.0, blue: 208/255.0, alpha: 1)
  
  override func draw(_ rect: CGRect) {
    let context = UIGraphicsGetCurrentContext()!
    
    context.drawLinearGradient(rect: bounds, startColor: UIColor.white, endColor: lightGrayColor)
    
    var strokeRect = bounds
    context.setStrokeColor(UIColor.white.cgColor)
    context.setLineWidth(1)
    strokeRect.size.height -= 1
    context.stroke(strokeRect.rectFor1PxStroke())
    
    let startPoint = CGPoint(x: bounds.origin.x, y: bounds.origin.y + bounds.size.height - 1)
    let endPoint = CGPoint(x: bounds.origin.x + bounds.width - 1, y: bounds.origin.y + bounds.size.height - 1)
    
    context.draw1PxStroke(startPoint: startPoint, endPoint: endPoint, color: separatorColor)
  }
}
