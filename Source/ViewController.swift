import UIKit
import Metal
import MetalKit

let kludgeAutoLayout:Bool = false
let scrnSz:[CGPoint] = [ CGPoint(x:768,y:1024), CGPoint(x:834,y:1112), CGPoint(x:1024,y:1366) ] // portrait
let scrnIndex = 0
let scrnLandscape:Bool = true

var vc:ViewController! = nil
var control = Control()

class ViewController: UIViewController,UIPopoverPresentationControllerDelegate {
    var timer = Timer()
    
    @IBOutlet var flam3View: Flam3View!
    @IBOutlet var widgetView: WidgetView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        
        control.xscale = 400
        
        widgetView.initialize()
        
        rotated()
        reset()
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:)))
        tap2.numberOfTapsRequired = 2
        flam3View.addGestureRecognizer(tap2)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0/30.0, target:self, selector: #selector(timerHandler), userInfo: nil, repeats:true)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    //MARK: -
    
    var updateCounter:Int = 0
    
    func startUpdate(_ clearScreen:Bool = true) {
        control.yscale = control.xscale * control.ratio
        updateCounter = 120
        if clearScreen { clear() }
    }
    
    @objc func timerHandler() {
        if widgetView.update() {
            startUpdate()
        }
        
        if updateCounter > 0 {
            updateCounter -= 1
            flam3View.updateImage()
        }
    }
    
    //MARK: -
    
    func reset() {
        removeAllFocus()
        controlReset()
        controlLoaded()
        startUpdate()
    }
    
    func random() {
        controlRandom()
        controlLoaded()
        startUpdate()
    }
    
    func clear() { flam3View.clearImage() }
    
    func removeAllFocus() {
        for g in globalSList { g.stopFocus() }
        for g in globalDList { g.stopFocus() }
    }
    
    func focusMovement(_ pt:CGPoint) {
        for g in globalSList { if g.hasFocus { g.focusMovement(pt); return }}
        for g in globalDList { if g.hasFocus { g.focusMovement(pt); return }}
    }
    
    func controlLoaded() {
        widgetView.controlLoaded()
        startUpdate()
    }
    
    //MARK: -
    
    var bPtr:UIButton! = nil
    var groupIndex:Int = 0
    var indexPointer:UnsafeMutableRawPointer! = nil
    
    func launchFunctionIndexPopover(_ b:UIButton, _ v:UnsafeMutableRawPointer) {
        bPtr = b
        indexPointer = v
        functionIndex = Int(indexPointer.load(as: Int32.self))
        performSegue(withIdentifier: "FListSegue", sender: self)
    }
    
    func functionNameChanged() {
        indexPointer.storeBytes(of:Int32(functionIndex), as:Int32.self)
        bPtr.setTitle(varisNames[functionIndex], for: .normal)
        startUpdate()
    }
    
    func launchColorPopover(_ nGroupIndex:Int, _ b:UIButton, _ v:UnsafeMutableRawPointer) {
        bPtr = b
        indexPointer = v
        groupIndex = nGroupIndex
        colorIndex = Int(indexPointer.load(as: Int32.self))
        performSegue(withIdentifier: "ColorSegue", sender: self)
    }
    
    func colorChanged() {
        indexPointer.storeBytes(of:Int32(colorIndex), as:Int32.self)
        bPtr.backgroundColor = uiColorFromIndex(colorIndex)
        updateGroupRGB(Int32(groupIndex),Int32(colorIndex))
        startUpdate()
    }
    
    //MARK: -
    
    @objc func rotated() {
        var wxs = view.bounds.width
        var wys = view.bounds.height
        if kludgeAutoLayout {
            wxs = scrnLandscape ? scrnSz[scrnIndex].y : scrnSz[scrnIndex].x
            wys = scrnLandscape ? scrnSz[scrnIndex].x : scrnSz[scrnIndex].y
        }
        
        control.ratio = Float(wxs) / Float(wys) // used when stretching drawing to fit UIImageView
        
        let wWidth:CGFloat = 380
        let wHeight:CGFloat = 408
        
        flam3View.frame = CGRect(x:0, y:0, width:wxs, height:wys)
        widgetView.frame = CGRect(x:10, y:wys-wHeight-10, width:wWidth, height:wHeight)
    }
    
    //MARK: -
    
    func stopAllDeltas() {
        for g in globalSList { g.stop() }
        for g in globalDList { g.stop() }
        startUpdate(false)
    }
    
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        widgetView.isHidden = !widgetView.isHidden
        stopAllDeltas()
    }
    
    let scaleMin:Float = 2
    let scaleMax:Float = 1200
    var startPinch:Float = 0
    
    @IBAction func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            startPinch = control.xscale
        }
        if sender.state == .ended {
            startUpdate()
            return
        }

        control.xscale = fClamp(startPinch * Float(sender.scale),scaleMin,scaleMax)
        stopAllDeltas()
        flam3View.updateImage()
    }
}
