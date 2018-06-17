import UIKit
import simd

class DeltaView: UIView {
    var context : CGContext?
    var scenter = float2()
    var swidth = float2()
    var ident:Int = 0
    var active = true
    var fastEdit = true
    var highLightPoint = CGPoint()
    var valuePointerX:UnsafeMutableRawPointer! = nil
    var valuePointerY:UnsafeMutableRawPointer! = nil
    var deltaValue:Float = 0
    var name:String = "name"
    var hasFocus = false
    var deltaX:Float = 0
    var deltaY:Float = 0
    var touched = false
    
    var min:Float = 0
    var max:Float = 256

    func initializeFloats(_ vx:UnsafeMutableRawPointer, _ vy:UnsafeMutableRawPointer, _ vmin:Float, _ vmax:Float,  _ delta:Float, _ iname:String) {
        valuePointerX = vx
        valuePointerY = vy
        min = vmin
        max = vmax
        deltaValue = delta
        name = iname

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
    }
    
    func stop() { deltaX = 0; deltaY = 0 }
    
    func resetDeltas() {
        stop()
        touched = false
        setNeedsDisplay()
    }

    func stopFocus() {
        deltaX = 0
        deltaY = 0
        if hasFocus {
            hasFocus = false
            setNeedsDisplay()
        }
    }

    @objc func handleTap1(_ sender: UITapGestureRecognizer) {
        vc.removeAllFocus()
        hasFocus = true
        resetDeltas()
    }
    
    @objc func handleTap2(_ sender: UITapGestureRecognizer) {
        fastEdit = !fastEdit
        resetDeltas()
    }

    @objc func handleTap3(_ sender: UITapGestureRecognizer) {
        if valuePointerX == nil || valuePointerY == nil { return }

        let value:Float = 0
        if let valuePointerX = valuePointerX { valuePointerX.storeBytes(of:value, as:Float.self) }
        if let valuePointerY = valuePointerY { valuePointerY.storeBytes(of:value, as:Float.self) }

        resetDeltas()
    }

    func highlight(_ x:CGFloat, _ y:CGFloat) {
        highLightPoint.x = x
        highLightPoint.y = y
    }

    func setActive(_ v:Bool) {
        active = v
        setNeedsDisplay()
    }

    func percentX(_ percent:CGFloat) -> CGFloat { return CGFloat(bounds.size.width) * percent }

    func boundsChanged() {
        swidth.x = Float(bounds.width)
        swidth.y = Float(bounds.height)
        scenter.x = swidth.x / 2
        scenter.y = swidth.y / 2
        setNeedsDisplay()
    }

    //MARK: ==================================

    override func draw(_ rect: CGRect) {
        if swidth.x == 0 { boundsChanged() }  // coldstart

        context = UIGraphicsGetCurrentContext()

        if !active {
            let G:CGFloat = 0.13        // color Lead
            UIColor(red:G, green:G, blue:G, alpha: 1).set()
            UIBezierPath(rect:bounds).fill()
            return
        }

        let limColor = UIColor(red:0.25, green:0.25, blue:0.2, alpha: 1)
        let nrmColorFast = UIColor(red:0.25, green:0.2, blue:0.2, alpha: 1)
        let nrmColorSlow = UIColor(red:0.2, green:0.25, blue:0.2, alpha: 1)

        if fastEdit { nrmColorFast.set() } else { nrmColorSlow.set() }
        UIBezierPath(rect:bounds).fill()

        if isMinValue(0) {  // X coord
            limColor.set()
            var r = bounds
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }
        else if isMaxValue(0) {
            limColor.set()
            var r = bounds
            r.origin.x += bounds.width/2
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }

        if isMaxValue(1) {  // Y coord
            limColor.set()
            var r = bounds
            r.size.height /= 2
            UIBezierPath(rect:r).fill()
        }
        else if isMinValue(1) {
            limColor.set()
            var r = bounds
            r.origin.y += bounds.width/2
            r.size.height /= 2
            UIBezierPath(rect:r).fill()
        }

        // edge -------------------------------------------------
        let ctx = context!
        ctx.saveGState()
        let path = UIBezierPath(rect:bounds)
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(2)
        ctx.addPath(path.cgPath)
        ctx.strokePath()
        ctx.restoreGState()

        UIColor.black.set()
        context?.setLineWidth(2)

        drawVLine(context!,CGFloat(scenter.x),0,bounds.height)
        drawHLine(context!,0,bounds.width,CGFloat(scenter.y))

        // cursor -------------------------------------------------
        let x = valueRatio(0) * bounds.width
        let y = (CGFloat(1) - valueRatio(1)) * bounds.height
        drawFilledCircle(context!,CGPoint(x:x,y:y),8,UIColor.black.cgColor)

        if hasFocus {
            context?.setLineWidth(2)
            UIColor.red.setStroke()
            UIBezierPath(rect:bounds).stroke()
        }
        
        drawText(10,8,.white,16,name)
    }

    //MARK: ==================================

    func getValue(_ who:Int) -> Float {
        switch who {
        case 0 :
            if valuePointerX == nil { return 0 }
            let vx = valuePointerX.load(as: Float.self)
            return vx
        case 1 :
            if valuePointerY == nil { return 0 }
            return valuePointerY.load(as: Float.self)
        default : fatalError("wrong subscript")
        }
    }

    func isMinValue(_ who:Int) -> Bool {
        if valuePointerX == nil { return false }

        return getValue(who) == min
    }

    func isMaxValue(_ who:Int) -> Bool {
        if valuePointerX == nil { return false }

        return getValue(who) == max
    }

    func valueRatio(_ who:Int) -> CGFloat {
        let den = max - min
        if den == 0 { return CGFloat(0) }
        return CGFloat((getValue(who) - min) / den )
    }

    //MARK: ==================================

    func update() -> Bool {
        if valuePointerX == nil || valuePointerY == nil || !active || !touched { return false }

        let valueX = fClamp(getValue(0) + deltaX * deltaValue, min,max)
        let valueY = fClamp(getValue(1) + deltaY * deltaValue, min,max)
        if let valuePointerX = valuePointerX { valuePointerX.storeBytes(of:valueX, as:Float.self) }
        if let valuePointerY = valuePointerY { valuePointerY.storeBytes(of:valueY, as:Float.self) }

        setNeedsDisplay()
        return true
    }

    //MARK: ==================================
    
    func focusMovement(_ pt:CGPoint) {
        if pt.x == 0 { touched = false; return }
        
        deltaX =  Float(pt.x) / 1000
        deltaY = -Float(pt.y) / 1000
        
        if !fastEdit {
            deltaX /= 100
            deltaY /= 100
        }
        
        touched = true
        setNeedsDisplay()
    }
    
    //MARK: ==================================

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !active { return }
        if valuePointerX == nil || valuePointerY == nil { return }

        for t in touches {
            let pt = t.location(in: self)

            deltaX = +(Float(pt.x) - scenter.x) / swidth.x / 10
            deltaY = -(Float(pt.y) - scenter.y) / swidth.y / 10

            if !fastEdit {
                deltaX /= 1000
                deltaY /= 1000
            }

            touched = true
            setNeedsDisplay()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { touchesBegan(touches, with:event) }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touched = false
    }
}

// MARK:

func drawLine(_ context:CGContext, _ p1:CGPoint, _ p2:CGPoint) {
    context.beginPath()
    context.move(to:p1)
    context.addLine(to:p2)
    context.strokePath()
}

func drawVLine(_ context:CGContext, _ x:CGFloat, _ y1:CGFloat, _ y2:CGFloat) { drawLine(context,CGPoint(x:x,y:y1),CGPoint(x:x,y:y2)) }
func drawHLine(_ context:CGContext, _ x1:CGFloat, _ x2:CGFloat, _ y:CGFloat) { drawLine(context,CGPoint(x:x1, y:y),CGPoint(x: x2, y:y)) }

func drawFilledCircle(_ context:CGContext, _ center:CGPoint, _ diameter:CGFloat, _ color:CGColor) {
    context.beginPath()
    context.addEllipse(in: CGRect(x:CGFloat(center.x - diameter/2), y:CGFloat(center.y - diameter/2), width:CGFloat(diameter), height:CGFloat(diameter)))
    context.setFillColor(color)
    context.fillPath()
}

