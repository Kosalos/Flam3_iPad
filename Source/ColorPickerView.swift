import UIKit

var colorIndex:Int = 0

func uiColorFromIndex(_ index:Int) -> UIColor {
    var r = Float(), g = Float(), b = Float()
    rgbForIndex(Int32(index),&r,&g,&b)
    return UIColor(red:CGFloat(r), green:CGFloat(g), blue:CGFloat(b), alpha: 1)
}

class ColorPickerView: UIView {
    let count:Int = 22  // colorLookup.count
    var xs = CGFloat()
    var ys = CGFloat()
    
    override func draw(_ rect: CGRect) {
        xs = bounds.width / 9
        ys = bounds.height / CGFloat(count)
        
        var index:Int = 0
        var rect = CGRect(x:0, y:0, width:xs-2, height:ys-2)
        
        for y in 0 ..< count {
            rect.origin.y = CGFloat(y) * ys + 1
            
            for x in 2 ... 10 {     // 9 entries 
                rect.origin.x = CGFloat(x-2) * xs + 1

                uiColorFromIndex(index).setFill()
                UIBezierPath(rect:rect).fill()
                
                index += 1
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pt = touch.location(in: self)
            colorIndex = Int(pt.x / xs) + Int(pt.y / ys) * 9
            vc.colorChanged()
            cvc.dismiss(animated: false, completion:nil)
        }
    }
}
