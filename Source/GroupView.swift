import UIKit
import simd

var globalSList:[SliderView] = []
var globalDList:[DeltaView] = []

class GroupView : UIView {
    var index = Int32()
    var wt = SliderView()
    var w1 = SliderView()
    var w2 = SliderView()
    var w3 = SliderView()
    var r1 = SliderView()
    var r2 = SliderView()
    var r3 = SliderView()
    var t1 = DeltaView()
    var t2 = DeltaView()
    var t3 = DeltaView()
    var s1 = DeltaView()
    var s2 = DeltaView()
    var s3 = DeltaView()
    var sList:[SliderView]! = nil
    var dList:[DeltaView]! = nil

    let activeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Active", for: .normal)
        btn.addTarget(self, action: #selector(activeTapped), for: .touchUpInside)
        return btn
    }()

    let colorButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("", for: .normal)
        btn.backgroundColor = .darkGray
        btn.addTarget(self, action: #selector(colorTapped), for: .touchUpInside)
        return btn
    }()
    
    let functionName1: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .darkGray
        btn.addTarget(self, action: #selector(functionName1Tapped), for: .touchUpInside)
        return btn
    }()

    let functionName2: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .darkGray
        btn.addTarget(self, action: #selector(functionName2Tapped), for: .touchUpInside)
        return btn
    }()

    let functionName3: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .darkGray
        btn.addTarget(self, action: #selector(functionName3Tapped), for: .touchUpInside)
        return btn
    }()

    //MARK: -

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func initialize(_ nIndex:Int) {
        index = Int32(nIndex)
        
        sList = [ wt,w1,w2,w3,r1,r2,r3 ]
        dList = [ t1,t2,t3,s1,s2,s3 ]
        for s in sList {
            addSubview(s)
            globalSList.append(s)
        }
        for d in dList {
            addSubview(d)
            globalDList.append(d)
        }

        addSubview(activeButton)
        addSubview(colorButton)
        addSubview(functionName1)
        addSubview(functionName2)
        addSubview(functionName3)

        functionName1.setTitle("FunctionName", for: .normal)
        functionName2.setTitle("FunctionName", for: .normal)
        functionName3.setTitle("FunctionName", for: .normal)

        // ----------------------------------------------------------
        setControlPointer(&control);

        let wMin:Float = 0
        let wMax:Float = 1
        let wChg:Float = 0.01
        let pMin:Float = -2
        let pMax:Float = +2
        let pChg:Float = 0.02
        let sMin:Float = 0.5
        let sMax:Float = +2
        let sChg:Float = 0.02
        
        wt.initializeFloat(groupWtPointer(index),  .delta,wMin,wMax,wChg,"W")
        w1.initializeFloat(funcWhtPointer(index,0),.delta,wMin,wMax,wChg,"W")
        w2.initializeFloat(funcWhtPointer(index,1),.delta,wMin,wMax,wChg,"W")
        w3.initializeFloat(funcWhtPointer(index,2),.delta,wMin,wMax,wChg,"W")
        r1.initializeFloat(funcRotPointer(index,0),.delta,pMin,pMax,pChg,"R")
        r2.initializeFloat(funcRotPointer(index,0),.delta,pMin,pMax,pChg,"R")
        r3.initializeFloat(funcRotPointer(index,0),.delta,pMin,pMax,pChg,"R")
        t1.initializeFloats(funcXtPointer(index,0),funcYtPointer(index,0),pMin,pMax,pChg,"T")
        t2.initializeFloats(funcXtPointer(index,1),funcYtPointer(index,1),pMin,pMax,pChg,"T")
        t3.initializeFloats(funcXtPointer(index,2),funcYtPointer(index,2),pMin,pMax,pChg,"T")
        s1.initializeFloats(funcXsPointer(index,0),funcYsPointer(index,0),sMin,sMax,sChg,"S")
        s2.initializeFloats(funcXsPointer(index,1),funcYsPointer(index,1),sMin,sMax,sChg,"S")
        s3.initializeFloats(funcXsPointer(index,2),funcYsPointer(index,2),sMin,sMax,sChg,"S")

        // ----------------------------------------------------------
        var x = CGFloat(), y = CGFloat()
        
        func frame(_ fxs:CGFloat, _ fys:CGFloat, _ dx:CGFloat, _ dy:CGFloat) -> CGRect {
            let r = CGRect(x:x, y:y, width:fxs, height:fys)
            x += dx; y += dy
            return r
        }

        let sWidth:CGFloat = 40
        let sGap:CGFloat = sWidth+5
        let sHeight:CGFloat = 30
        let fnWidth:CGFloat = 110

        x = 5
        y = 5
        activeButton.frame = frame(60,sHeight,70,0)
        functionName1.frame = frame(fnWidth,sHeight,fnWidth+5,0)
        w1.frame = frame(sWidth,sHeight,sGap,0)
        let q1 = [ t1,s1,r1 ]
        for q in q1 { q.frame = frame(sWidth,sHeight,sGap,0) }
        x = 5
        y += 40
        
        wt.frame = frame(60,sHeight,70,0)
        functionName2.frame = frame(fnWidth,sHeight,fnWidth+5,0)
        w2.frame = frame(sWidth,sHeight,sGap,0)
        let q2 = [ t2,s2,r2 ]
        for q in q2 { q.frame = frame(sWidth,sHeight,sGap,0) }
        x = 5
        y += 40
        
        colorButton.frame = frame(60,sHeight,70,0)
        functionName3.frame = frame(fnWidth,sHeight,fnWidth+5,0)
        w3.frame = frame(sWidth,sHeight,sGap,0)
        let q3 = [ t3,s3,r3 ]
        for q in q3 { q.frame = frame(sWidth,sHeight,sGap,0) }
    }
    
    func setActiveButtonColor() {
        let onoff = getGroupActive(index)
        activeButton.setTitleColor(onoff == 1 ? .green : .lightGray, for:.normal)
    }

    @objc func activeTapped() {
        let onoff = 1 - getGroupActive(index)
        setGroupActive(index,onoff)
        setActiveButtonColor()
        vc.startUpdate()
    }

    func controlLoaded() {
        setActiveButtonColor()
        functionName1.setTitle(varisNames[Int(funcIndex(index,0))], for: .normal)
        functionName2.setTitle(varisNames[Int(funcIndex(index,1))], for: .normal)
        functionName3.setTitle(varisNames[Int(funcIndex(index,2))], for: .normal)

        let colorIndex = Int(groupColorIndex(index))
        colorButton.backgroundColor = uiColorFromIndex(colorIndex)
        updateGroupRGB(index,Int32(colorIndex))
        
        for s in sList { s.setNeedsDisplay() }
        for d in dList { d.setNeedsDisplay() }
    }
    
    @objc func functionName1Tapped() { vc.launchFunctionIndexPopover(functionName1,funcIndexPointer(index,0)) }
    @objc func functionName2Tapped() { vc.launchFunctionIndexPopover(functionName2,funcIndexPointer(index,1)) }
    @objc func functionName3Tapped() { vc.launchFunctionIndexPopover(functionName3,funcIndexPointer(index,2)) }

    @objc func colorTapped() { vc.launchColorPopover(Int(index),colorButton,groupColorIndexPointer(index)) }

    override func draw(_ rect: CGRect) {
        UIColor(red:0.15, green:0.15, blue:0.15, alpha:1).setFill()
        UIBezierPath(rect:rect).fill()
    }
}
