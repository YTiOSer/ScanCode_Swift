//
//  QGToast.swift
//  B2BAutoziMall
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import UIKit

// 枚举类型
enum iToastGravity:Int{
    case top = 1000001
    case bottom
    case center
    func typeName() -> String {
        return "iToastGravity"
    }
}

class ToastSettingClass:NSObject {
    
    var textFont:CGFloat
    var duration:CGFloat
    var position:iToastGravity
    
    override init(){
        textFont = 14
        duration = 2
        position = iToastGravity.bottom
        super.init()
    }
}

class QGToast: NSObject {
    var toastSetting:ToastSettingClass!
    var frameMarginSize:CGFloat! = 10
    var frameSize:CGSize = CGSize(width: kScreenW - 40, height: 265)
    var view:UIView!
    
    
    /// 初始化
    ///
    /// 提示
    ///
    ///     QGToast(text:String,duration:TimeInterval)
    ///
    /// - Parameter text: 提示信息.
    /// - Parameter duration: 显示多长时间.
    ///
    /// - Returns: QGToast.
    ///
    /// - Complexity: O(*n*), where *n* is the number of elements to drop.
    
    init(text:String,duration:TimeInterval) {
        super.init()
        toastSetting = ToastSettingClass()
        let textFont = toastSetting.textFont
        let size:CGSize = self.sizeWithString(text as NSString, font: UIFont.systemFont(ofSize: textFont))
        
        let label:UILabel = UILabel (frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        label.text = text
        label.font = UIFont.systemFont(ofSize: textFont)
        label.numberOfLines = 0;
        label.textColor = UIColor.white
        
        var window:UIWindow = findLastWindowInScreen()
        if #available(iOS 11.0, *) {
            window = findFirstWindowInScreen()
        }
        
        let v:UIButton = UIButton(frame:CGRect(x: 0, y: 0, width: size.width + frameMarginSize, height: size.height + frameMarginSize))
        label.center = CGPoint(x: v.frame.size.width / 2, y: v.frame.size.height / 2);
        v.addSubview(label)
        
        v.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        v.layer.cornerRadius = 5
        var point:CGPoint = CGPoint(x: window.frame.size.width/2, y: window.frame.size.height/5*4);
        point = CGPoint(x: point.x , y: point.y + 10);
        v.center = point
        
        window.addSubview(v)
        view = v
        
        v.addTarget(self, action: #selector(QGToast.hideToast), for: UIControlEvents.touchDown)
        let timer:Timer = Timer(timeInterval: duration, target: self, selector: #selector(QGToast.hideToast), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    func sizeWithString(_ string:NSString, font:UIFont)-> CGSize {
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = string.boundingRect(with: frameSize, options:options, attributes: [NSAttributedStringKey(rawValue: "NSFontAttributeName"): font], context: nil)
        return rect.size
    }
    
    @objc func hideToast(){
        UIView.animate(withDuration: 0.2, animations: {
            () -> ()in
            self.view.alpha = 0
            }, completion: {
                (Boolean) -> ()in
                self.view.removeFromSuperview()
        })
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let kScreenBounds = UIScreen.main.bounds

func findLastWindowInScreen() -> UIWindow {
    let windows = UIApplication.shared.windows
    let windowCount = windows.count
    var windowTemp = UIWindow()
    for i in 0..<windowCount {
        let window = windows[windowCount - i - 1]
        if kScreenBounds.contains(window.frame) && !window.isHidden { windowTemp = window; break }
    }
    return windowTemp
}
func findFirstWindowInScreen() -> UIWindow {
    let windows = UIApplication.shared.windows
    let windowCount = windows.count
    var windowTemp = UIWindow()
    for i in 0..<windowCount {
        let window = windows[i]
        if kScreenBounds.contains(window.frame) && !window.isHidden { windowTemp = window; break }
    }
    return windowTemp
}
