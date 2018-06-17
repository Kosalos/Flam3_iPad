import UIKit

let limColor = UIColor(red:0.25, green:0.25, blue:0.2, alpha: 0.4)
let nrmColorFast = UIColor(red:0.35, green:0.2, blue:0.2, alpha: 0.4)
let nrmColorSlow = UIColor(red:0.2, green:0.25, blue:0.2, alpha: 0.4)
let widgetEdgeColor = UIColor.black
let textColor = UIColor.white

enum ValueType { case int32,float }
enum SliderType { case delta,direct }

class SliderView: UIView {
    var context : CGContext?
    var scenter:Float = 0
    var swidth:Float = 0
    var ident:Int = 0
    var active = true
    var fastEdit = true
    var hasFocus = false
    var valuePointer:UnsafeMutableRawPointer! = nil
    var valuetype:ValueType = .float
    var slidertype:SliderType = .delta
    var deltaValue:Float = 0
    var name:String = "name"

    var min:Float = 0
    var max:Float = 256
    
    func initializeCommon() {
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap1(_:)))
        tap1.numberOfTapsRequired = 1
        addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap2(_:)))
        tap2.numberOfTapsRequired = 2
        addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap3(_:)))
        tap3.numberOfTapsRequired = 3
        addGestureRecognizer(tap3)
        
        isUserInteractionEnabled = true
        self.backgroundColor = .clear
    }
    
    func initializeInt32(_ v:UnsafeMutableRawPointer, _ sType:SliderType, _ vmin:Float, _ vmax:Float,  _ delta:Float, _ iname:String) {
        valuePointer = v
        valuetype = .int32
        slidertype = sType
        min = vmin
        max = vmax
        deltaValue = delta
        name = iname
        initializeCommon()
    }

    func initializeFloat(_ v:UnsafeMutableRawPointer, _ sType:SliderType, _ vmin:Float, _ vmax:Float,  _ delta:Float, _ iname:String) {
        valuePointer = v
        valuetype = .float
        slidertype = sType
        min = vmin
        max = vmax
        deltaValue = delta
        name = iname
        initializeCommon()
    }

    func setActive(_ v:Bool) {
        active = v
        setNeedsDisplay()
    }
    
    func percentX(_ percent:CGFloat) -> CGFloat { return CGFloat(bounds.size.width) * percent }
    
    func boundsChanged() {
        swidth = Float(bounds.width)
        scenter = swidth / 2
        setNeedsDisplay()
    }
    
    func stop() { delta = 0 }
    
    func stopFocus() {
        delta = 0
        if hasFocus {
            hasFocus = false
            setNeedsDisplay()
        }
    }
    
    //MARK: ==================================
    
    @objc func handleTap1(_ sender: UITapGestureRecognizer) {
        vc.removeAllFocus()
        hasFocus = true
        delta = 0
        setNeedsDisplay()
    }
    
    @objc func handleTap2(_ sender: UITapGestureRecognizer) {
        fastEdit = !fastEdit
        delta = 0
        setNeedsDisplay()
    }
    
    @objc func handleTap3(_ sender: UITapGestureRecognizer) {
        if valuePointer == nil { return }
        
        let value:Float = 0

        switch valuetype {
        case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
        case .float : valuePointer.storeBytes(of:value, as:Float.self)
        }
        
        handleTap2(sender) // undo the double tap that was also recognized
    }
    
    //MARK: ==================================

    override func draw(_ rect: CGRect) {
        if swidth == 0 { boundsChanged() }  // coldstart
        
        context = UIGraphicsGetCurrentContext()
        
        if !active {
            let G:CGFloat = 0.13        // color Lead
            UIColor(red:G, green:G, blue:G, alpha: 1).set()
            UIBezierPath(rect:bounds).fill()
            return
        }
        
        if fastEdit { nrmColorFast.set() } else { nrmColorSlow.set() }
        UIBezierPath(rect:bounds).fill()
        
        if isMinValue() {
            limColor.set()
            var r = bounds
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }
        else if isMaxValue() { 
            limColor.set()
            var r = bounds
            r.origin.x += bounds.width/2
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }
        
        // edge -------------------------------------------------
        context!.setStrokeColor(UIColor.black.cgColor)

        let path = UIBezierPath(rect:bounds)
        context!.setLineWidth(2)
        context!.addPath(path.cgPath)
        context!.strokePath()

        // cursor -------------------------------------------------
        let x = valueRatio() * bounds.width
        context!.setStrokeColor(widgetEdgeColor.cgColor)
        context!.setLineWidth(4)
        path.removeAllPoints()
        path.move(to: CGPoint(x:x, y:0))
        path.addLine(to: CGPoint(x:x, y:bounds.height))
        context!.addPath(path.cgPath)
        context!.strokePath()
        
        drawText(10,8,textColor,16,name)
        
        if hasFocus {
            UIColor.red.setStroke()
            UIBezierPath(rect:bounds).stroke()
        }
    }
    
    var delta:Float = 0
    var touched = false

    //MARK: ==================================

    func getValue() -> Float {
        if valuePointer == nil { return 0 }
        var value:Float = 0
        
        switch valuetype {
        case .int32 : value = Float(valuePointer.load(as: Int32.self))
        case .float : value = valuePointer.load(as: Float.self)
        }

        return value
    }
    
    func isMinValue() -> Bool {
        if valuePointer == nil { return false }
        return getValue() == min
    }
    
    func isMaxValue() -> Bool {
        if valuePointer == nil { return false }
        return getValue() == max
    }
    
    func valueRatio() -> CGFloat {
        let den = max - min
        if den == 0 { return CGFloat(0) }
        return CGFloat((getValue() - min) / den )
    }
    
    //MARK: ==================================
    
    func update() -> Bool {
        if valuePointer == nil || !active || !touched { return false }

        var value = getValue()
        let oldValue = value
        
        value = fClamp(value + delta * deltaValue, min,max)
        
        if value != oldValue {
            switch valuetype {
            case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
            case .float : valuePointer.storeBytes(of:value, as:Float.self)
            }
            
            setNeedsDisplay()
            return true
        }
        
        return false
    }
    
    //MARK: ==================================

    func focusMovement(_ pt:CGPoint) {
        if pt.x == 0 { touched = false; return }
        
        delta = Float(pt.x) / 1000
        
        if !fastEdit {
            delta /= 100
        }
        
        touched = true
        setNeedsDisplay()
    }
    
    //MARK: ==================================

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if valuePointer == nil || !active { return }
        
        for t in touches {
            let pt = t.location(in: self)
            
            touched = true
            
            if slidertype == .direct {
                let value = fClamp(min + (max - min) * Float(pt.x) / swidth, min,max)

                switch valuetype {
                case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
                case .float : valuePointer.storeBytes(of:value, as:Float.self)
                }
            }
            else {
                delta = (Float(pt.x) - scenter) / swidth / 10
                
                if !fastEdit {
                    delta /= 100
                }
            }
            
            setNeedsDisplay()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { touchesBegan(touches, with:event) }    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { touched = false }
}

func fClamp(_ v:Float, _ min:Float, _ max:Float) -> Float {
    if v < min { return min }
    if v > max { return max }
    return v
}

