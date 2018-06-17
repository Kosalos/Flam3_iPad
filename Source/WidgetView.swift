import UIKit
import simd

class WidgetView : UIView {
    var gList:[GroupView]! = nil
    
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var saveLoadButton: UIButton!
    @IBOutlet var helpButton: UIButton!
    @IBOutlet var randomButton: UIButton!
    @IBOutlet var g1: GroupView!
    @IBOutlet var g2: GroupView!
    @IBOutlet var g3: GroupView!

    @IBAction func resetPressed(_ sender: UIButton) { vc.reset() }
    @IBAction func randomPressed(_ sender: UIButton) { vc.random() }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func initialize() {
        gList = [ g1,g2,g3 ]
        g1.initialize(0)
        g2.initialize(1)
        g3.initialize(2)
        
        var x = CGFloat(), y = CGFloat()
        
        func frame(_ fxs:CGFloat, _ fys:CGFloat, _ dx:CGFloat, _ dy:CGFloat) -> CGRect {
            let r = CGRect(x:x, y:y, width:fxs, height:fys)
            x += dx; y += dy
            return r
        }
        
        x = 5
        y = 2
        let sHeight:CGFloat = 30
        let xHop:CGFloat = 100
        resetButton.frame = frame(60,sHeight,xHop,0)
        randomButton.frame = frame(60,sHeight,xHop,0)
        saveLoadButton.frame = frame(80,sHeight,xHop+20,0)
        helpButton.frame = frame(40,sHeight,0,0)
        
        x = 5
        y += 32
        let gWidth:CGFloat = 410
        let gHeight:CGFloat = 120
        for g in gList { g.frame = frame(gWidth,gHeight,0,gHeight+5) }
    }
    
    func controlLoaded() { for g in gList { g.controlLoaded() }}
    
    override func draw(_ rect: CGRect) {
        UIColor(red:0.1, green:0.1, blue:0.1, alpha:1).setFill()
        UIBezierPath(rect:rect).fill()
    }
    
    func update() -> Bool {
        var refresh = false
        for g in globalSList { if g.update() { refresh = true }}
        for g in globalDList { if g.update() { refresh = true }}
        return refresh
    }
}

// -------------------------------------------------------------------------

func drawText(_ x:CGFloat, _ y:CGFloat, _ color:UIColor, _ sz:CGFloat, _ str:String) {
    let paraStyle = NSMutableParagraphStyle()
    paraStyle.alignment = .left

    let font = UIFont(name: "Helvetica", size:sz)!

    let textFontAttributes: [NSAttributedStringKey: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paraStyle,
        ]

    str.draw(in: CGRect(x:x, y:y, width:800, height:100), withAttributes: textFontAttributes)
}
