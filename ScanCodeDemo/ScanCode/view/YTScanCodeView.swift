//
//  YTScanCodeView.swift
//  ScanCodeDemo
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import UIKit

let kScreenW = ScreenWidth //UIScreen.main.bounds.size.width
let kScreenH = ScreenHeight //UIScreen.main.bounds.size.height
let kScanVinCodeNotification = "ScanVinCodeNotification" //通知

typealias getVinCode = (String) -> Void   //定义闭包传递选中的分类信息
typealias clickBtnClouse = () -> Void

/**
 扫描模式
 - kScanDimensionCode：  二维码 一维码
 - kScanVinCode ：       VIN码
 - kOther：              其他
 */
public enum ScanModelState: Int {
    case kScanDimensionCode = 1
    case kScanVinCode = 2
    case kOther = 3
}

class YTScanCodeView: UIView {

    /**
     - kBack  返回按钮
     - kDimensionCode 二维码
     - kVinCode  Vin 码
     - kPhoto 拍照按钮
     - kRemakePhono 重拍按钮
     - kOKVinCode 确定按钮
     - kPhotoAlbum 相册
     */
    enum ButtonTagValue:Int {
        case kBack = 1000
        case kDimensionCode = 1001
        case kVinCode = 1002
        case kPhoto = 1003
        case kRemakePhono = 1004
        case kOKVinCode = 1005
        case kPhotoAlbum = 1006
    }
    
    var codeView: UIImageView! //扫描框
    var scrollLabel: UIImageView! //扫描线
    var toolbarView: UIView!
    
    var messageLabel: UILabel! //提示文字label
    var backButton: UIButton! // 返回
    var photoAlbumButton: UIButton! // 相册
    var vinButton: UIButton! //VIN
    var scanButton: UIButton! //二维码
    var photoButton: UIButton! //拍照
    var remakeButton: UIButton! //重拍
    var okVinCodeButton: UIButton! //确定
   
    var currentScanMode: ScanModelState! //扫码模式
   
    var arrayKeyboardButton  = [UIButton]() //自定义键盘
    var toolbarVertical: UIView!
    var imageClipView:UIImageView!
    
    fileprivate var alphaLeftBGView: UIView!//左边半透明
    fileprivate var alphaBottomBGView: UIView!//底部半透明
    fileprivate var alphaTopBGView: UIView!//顶部半透明
    fileprivate var vinCodeView: YTNoMenuTextField!
    fileprivate var keyBoardBGView: UIView!
    
    var didClickedBackButtonClosure: clickBtnClouse? //返回闭包
    var didClickedPhonoButtonClosure: clickBtnClouse? //拍照闭包
    var didClickedRemakeButtonClosure: clickBtnClouse? //重拍闭包
    var didClickedOKVinCodeButtonClosure: getVinCode? //VIN确定闭包
    var didClickedPhotoAlbumButtonClosure: clickBtnClouse? //相册闭包

    override init(frame: CGRect) {
        super.init(frame:frame)
        
        setUpCustomView()
        editVINCode(isEdit: false)
        photoAlbumButton.isHidden = true
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.3) //alpha
        
        NotificationCenter.default.addObserver(self, selector: #selector(YTScanCodeView.getVinCodeResult(notificaion:)), name: NSNotification.Name(rawValue: kScanVinCodeNotification), object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension YTScanCodeView{
 
    // MARK: -处理按钮点击事件
    @objc func didClickedButtonAction(btn: UIButton) {
        
        vinCodeView.isHidden = true
        switch btn.tag {
        case ButtonTagValue.kBack.rawValue :
            if let sureClosure = didClickedBackButtonClosure {
                sureClosure()
            }
        case ButtonTagValue.kDimensionCode.rawValue ://点击扫描二维码按钮
            scrollLabel.isHidden = false
            scanButton.isSelected = true
            vinButton.isSelected = false
            setScanModelState(scanType: .kScanDimensionCode)
        case ButtonTagValue.kPhoto.rawValue ://点击拍照按钮
            if let sureClosure = didClickedPhonoButtonClosure {
                sureClosure()
                self.editVINCode(isEdit: true)
            }
        case ButtonTagValue.kVinCode.rawValue ://点击扫描vin码按钮
            scrollLabel.isHidden = true
            scanButton.isSelected = false
            vinButton.isSelected = true
            setScanModelState(scanType: .kScanVinCode)
        case ButtonTagValue.kRemakePhono.rawValue ://点击重拍按钮
            if let sureClosure = didClickedRemakeButtonClosure {
                sureClosure()
                self.editVINCode(isEdit: false)
            }
        case ButtonTagValue.kOKVinCode.rawValue :
            self.didClickedOKVinCodeButtonClosure!(vinCodeView.text!)
        //从相册中选择
        case ButtonTagValue.kPhotoAlbum.rawValue:
            if let sureClosure = didClickedPhotoAlbumButtonClosure {
                sureClosure()
            }
        default :
            break
        }
    }
    
    //闭包变量
    func setBackClosure(SortInfo:@escaping getVinCode) {
        didClickedOKVinCodeButtonClosure = SortInfo
    }
    
    /**
     * 二维码扫描&Vin码扫描
     */
    internal func setScanModelState( scanType: ScanModelState) -> Void {
        currentScanMode = scanType
        switch scanType {
        case .kScanDimensionCode:
            // 隐藏拍照按钮
            photoButton.isHidden = true
            //设置按钮位置
            backButton.frame = CGRect(x: 10, y: 20, width: 32, height: 32)
            backButton.transform = .identity
            scanButton.transform = .identity
            vinButton.transform = .identity
            let scanSize:CGSize = CGSize(width: kScreenW*3/4, height: kScreenW*3/4)
            codeView.image = UIImage(named: "pick_bg")
            codeView.frame = CGRect(x: 0, y: 0, width: scanSize.width, height: scanSize.height)
            codeView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 45)
            messageLabel.isHidden = false
            self.editVINCode(isEdit: false)
            // 隐藏 冲相册选择按钮
            photoAlbumButton.isHidden = true
            
        case .kScanVinCode:
            photoButton.isHidden = false //显示拍照按钮
            photoAlbumButton.isHidden = false
            let rotation90 = CGAffineTransform(rotationAngle: CGFloat(degreesToRadians(90.0)))
            scanButton.transform = rotation90
            vinButton.transform = rotation90
            var l:CGFloat! = 160.0 + 80.0
            if kScreenH > 568 {
                l = 230 + 80.0
            }
            codeView.image = UIImage(named: "pick_vin_bg")
            codeView.frame = CGRect(x: 0, y: 0, width: 60, height: kScreenH - l)
            codeView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 30)
            messageLabel.isHidden = true
            self.imageClipView.frame = CGRect(x: (kScreenW - self.codeView.frame.width - 2), y: ((kScreenH - self.codeView.frame.height) / 2), width: self.codeView.frame.width, height: self.codeView.frame.height)
        default:
            break
        }
    }
    
}

// MARK: UI
extension YTScanCodeView{
    
    /**
     * 布局用户视图
     */
    private func setUpCustomView() {
        //初始化二维码为二维扫描模式
        currentScanMode = .kScanDimensionCode
        
        codeView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "pick_bg")
            self.addSubview(imageView)
            let scanSize:CGSize = CGSize(width: kScreenW*3/4, height: kScreenW*3/4)
            imageView.frame = CGRect(x: 0, y: 0, width: scanSize.width, height: scanSize.height)
            imageView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY - 45)
            
            return imageView
        }()
        // #0016898/0017158、0017157 add by whq at 2016-04-05 begin
        addAlphaBGView()
        // #0016898/0017158、0017157 add by whq at 2016-04-05 end
        messageLabel = {
            let label = UILabel()
            label.text = "将二维码放入框内,即可自动扫描"
            label.textColor = UIColor.white
            label.font = UIFont.systemFont(ofSize: 13.0)
            label.textAlignment = .center
            self.addSubview(label)
            label.frame = CGRect(x: 0, y: codeView.frame.maxY, width: kScreenW, height: 15)
            return label
        }()
        scrollLabel = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "line")
            imageView.isHidden = true
            self.addSubview(imageView)
            imageView.frame = CGRect(x: codeView.frame.minX, y: codeView.frame.minY, width: codeView.frame.width, height: 2)
            return imageView
        }()
        toolbarView = {
            let toolbar = UIView()
            toolbar.backgroundColor = UIColor.black
            toolbar.frame = CGRect(x: 0, y: kScreenH - 60, width: kScreenW, height: 60)
            self.addSubview(toolbar)
            return toolbar
        }()
        scanButton = {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "scan_dimension_code"), for: UIControlState.normal)
            button.setImage(UIImage(named: "scan_dimension_code_pre"), for: UIControlState.selected)
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kDimensionCode.rawValue
            toolbarView.addSubview(button)
            button.frame = CGRect.init(x: 10, y: 0, width: 60, height: 60)
            button.isSelected = true
            return button
        }()
        photoButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.setImage(UIImage(named: "scan_capture"), for: UIControlState.normal)
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kPhoto.rawValue
            toolbarView.addSubview(button)
            button.isHidden = true
            button.frame = CGRect(x: kScreenW/2-30, y: 0, width: 60, height: 60)
            return button
        }()
        vinButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.setImage(UIImage(named: "scan_vin_code"), for: UIControlState.normal)
            button.setImage(UIImage(named: "scan_vin_code_pre"), for: UIControlState.selected)
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kVinCode.rawValue
            toolbarView.addSubview(button)
            button.frame = CGRect(x: kScreenW-70, y: 0, width: 60, height: 60)
            return button
        }()
        // 初始化横屏的工具栏
        toolbarVertical = {
            let toolbar = UIView()
            toolbar.backgroundColor = UIColor.black
            toolbar.frame = CGRect(x: 0, y: 0, width: 50, height: kScreenH)
            toolbar.isHidden = true
            self.addSubview(toolbar)
            return toolbar
        }()
        remakeButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.setTitle("重 拍", for: .normal)
            button.setTitleColor(UIColor.yellow, for: .normal)
            button.backgroundColor = UIColor.black
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kRemakePhono.rawValue
            button.frame = CGRect(x: -20, y: kScreenH/4 - 100, width: 80, height: 40)
            button.transform = CGAffineTransform(rotationAngle: degreesToRadians(90))
            toolbarVertical.addSubview(button)
            return button
        }()
        okVinCodeButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.setTitle("确 定", for: .normal)
            button.setTitleColor(UIColor.green, for: .normal)
            button.backgroundColor = UIColor.black
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kOKVinCode.rawValue
            button.frame = CGRect(x: -20, y: kScreenH/4 * 3 + 20, width: 80, height: 40)
            button.transform = CGAffineTransform(rotationAngle: degreesToRadians(90))
            toolbarVertical.addSubview(button)
            return button
        }()
        imageClipView = {
            let imageView = UIImageView()
            self.addSubview(imageView)
            imageView.isHidden = true
            return imageView
        }()
        self.virtualKeyboard()
        backButton = {
            let button = UIButton(type: UIButtonType.custom)
            let avatarImage = UIImage(named: "app_b_back")
            button.setImage(avatarImage, for: UIControlState.normal)
            button.frame = CGRect(x: 10, y: 10, width: 32, height: 32)
            button.layer.cornerRadius = 16.0
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.clear.cgColor
            button.clipsToBounds = true
            button.alpha=0.5
            button.backgroundColor = UIColor.black
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kBack.rawValue
            self.addSubview(button)
            return button
        }()
        
        photoAlbumButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.setTitle("相册", for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.backgroundColor = UIColor.clear
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedButtonAction(btn:)), for: .touchUpInside)
            button.tag = ButtonTagValue.kPhotoAlbum.rawValue
            button.frame = CGRect(x: kScreenW-80, y: 10, width: 80, height: 25)
            // 隐藏 冲相册选择按钮
            button.isHidden = true
            self.addSubview(button)
            return button
        }()
    }
    /**
     *  设置透明度
     **/
    private func addAlphaBGView()
    {
        alphaTopBGView = UIView()
        alphaTopBGView.backgroundColor = UIColor.black
        alphaTopBGView.alpha = 0.5
        self.addSubview(alphaTopBGView)
        alphaTopBGView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(self)
            make.bottom.equalTo(codeView.snp.top)
        }
        alphaLeftBGView = UIView()
        alphaLeftBGView.backgroundColor = UIColor.black
        alphaLeftBGView.alpha = 0.5
        self.addSubview(alphaLeftBGView)
        alphaLeftBGView.snp.makeConstraints { (make) in
            make.top.equalTo(codeView.snp.top)
            make.left.equalTo(self.snp.left)
            make.right.equalTo(codeView.snp.left)
            make.bottom.equalTo(codeView.snp.bottom)
        }
        alphaBottomBGView = UIView()
        alphaBottomBGView.backgroundColor = UIColor.black
        alphaBottomBGView.alpha = 0.5
        self.addSubview(alphaBottomBGView)
        alphaBottomBGView.snp.makeConstraints { (make) in
            make.top.equalTo(codeView.snp.bottom)
            make.left.right.bottom.equalTo(self)
            //            make.bottom.equalTo(self.snp.bottom)
        }
        let alphaRightBGView = UIView()
        alphaRightBGView.backgroundColor = UIColor.black
        alphaRightBGView.alpha = 0.5
        self.addSubview(alphaRightBGView)
        alphaRightBGView.snp.makeConstraints { (make) in
            make.top.equalTo(codeView.snp.top)
            make.right.equalTo(self.snp.right)
            make.left.equalTo(codeView.snp.right)
            make.bottom.equalTo(codeView.snp.bottom)
        }
    }
    
}

// MARK: VIN码
extension YTScanCodeView{
    
    //MARK: - 创建VIN码
    /// A ** initvinCode** function
    private func initVINCode() -> Void {
        
        let buttonHeight: CGFloat = 40.0
        var buttonPosX: CGFloat = 220.0
        
        if kScreenH == 667 {
            buttonPosX = kScreenW/3*2+5
        }
        if kScreenH > 667 {  //736
            buttonPosX = kScreenW/3*2+10
        }
        let rotation90: CGAffineTransform  = CGAffineTransform(rotationAngle: degreesToRadians(90.0))
        let point = CGPoint.init(x: buttonPosX + 30, y: kScreenH / 2)
        keyBoardBGView = UIView()
        keyBoardBGView.frame = CGRect(x: 50, y: 0, width: buttonPosX - buttonHeight - 20, height: kScreenH)
        keyBoardBGView.backgroundColor = UIColor.gray
        keyBoardBGView.isHidden = true
        self.addSubview(keyBoardBGView)
        vinCodeView = YTNoMenuTextField()
        vinCodeView.isHidden = true
        vinCodeView.backgroundColor = UIColor.white
        vinCodeView.frame = CGRect(x: 0, y: 0, width: kScreenH - 50, height: buttonHeight)
        vinCodeView.center = point
        vinCodeView.transform = rotation90
        vinCodeView.textAlignment = .center
        vinCodeView.font = UIFont.systemFont(ofSize: 25.0)
        vinCodeView.becomeFirstResponder()
        vinCodeView.clearButtonMode = .whileEditing
        vinCodeView.inputView = UIView.init(frame: CGRect.zero)
        self.addSubview(vinCodeView)
    }
    
    // MARK: -
    func editVINCode(isEdit: Bool) {
        for  btn in arrayKeyboardButton {
            btn.isHidden = !isEdit
        }
        toolbarVertical.isHidden = !isEdit
        self.toolbarView.isHidden = isEdit
        self.toolbarVertical.isHidden = !isEdit
        self.imageClipView.isHidden = !isEdit
        vinCodeView.isHidden = !isEdit
        keyBoardBGView.isHidden = !isEdit
        backButton.isHidden = isEdit
        photoAlbumButton.isHidden = isEdit
        
    }
    // MARK: - 获取VIN 码
    func getVINCode() -> String {
        return vinCodeView.text!
    }
    //重拍的时候，把按钮上显示的文字设置为0
    func resetButtonTitle(){
        vinCodeView.text = ""
    }
    //MARK:响应扫描vin码后的消息通知
    @objc func getVinCodeResult(notificaion: NSNotification)
    {
        
        let dic = notificaion.object as? NSDictionary
        if dic?["errMsg"] as? String == "success"
        {
            guard let word = dic?["word"] as? String else{return}
            if word.isEmpty != true
            {
                DispatchQueue.main.async(execute: {//在主线程里刷新界面
                    self.vinCodeView.text = word
                })
            } else{
                DispatchQueue.main.async(execute: {//在主线程里刷新界面
                    self.showToast("识别失败，请重新拍摄")
                })
            }
        }else{
            DispatchQueue.main.async(execute: {//在主线程里刷新界面
                self.showToast("识别失败，请重新拍摄")
            })
            
        }
    }
    
}

// MARK: 虚拟键盘
extension YTScanCodeView{
    
    // MARK: - 虚拟键
    private func virtualKeyboard() -> Void {
        
        initVINCode()
        
        let arrayKeyCharacter = ["0","1","2","3","4","5","6","7","8","9","", "Q","W","E","R","T","Y","U","I","O","P", "" ,"A","S","D","F","G","H","J","K","L", "","Z", "X","C","V","B","N","M"]
        
        var interval: CGFloat = 5.0
        var buttonWidth: CGFloat = 40
        var buttonTempWidth: CGFloat = 40
        var buttonHeight:CGFloat = 30
        var buttonPosX: CGFloat = 170.0
        var buttonPosY: CGFloat = (kScreenH  - 445 - 44)/2
        var buttonsIntervals: CGFloat = 9.0
        if (kScreenH == 667 || kScreenH > 667) {
            interval = 8.0
            buttonPosX = kScreenW/3*2-55
            buttonWidth = 48
            buttonTempWidth = 48
            buttonHeight = 35
            buttonPosY = (kScreenH - buttonWidth * 11 - interval * 10)/2
            buttonsIntervals = 12.0
        }
        for charValue in arrayKeyCharacter {
            if charValue == "Q" {
                buttonPosX -= buttonWidth
                buttonPosY = (kScreenH - buttonWidth * 11 - interval * 10)/2
            }
            if charValue ==  "A" {
                buttonPosX -= buttonWidth
                buttonPosY = (kScreenH - buttonWidth * 11 - interval * 10)/2 + 3//按钮向下移动3个位置，进行微调
                buttonTempWidth = buttonWidth + (buttonWidth + interval) / 10
            }
            if charValue == "Z" {
                buttonPosX -= buttonWidth + buttonsIntervals
                buttonPosY = (kScreenH - buttonWidth * 11 - interval * 10)/2 + 14//按钮向下移动12个位置，进行微调
                buttonTempWidth = buttonWidth + (buttonWidth + interval) * 4 / 7
            }
            let rotation90: CGAffineTransform  = CGAffineTransform(rotationAngle: degreesToRadians(90.0))
            let frame: CGRect = CGRect(x: buttonPosX, y: buttonPosY, width: buttonTempWidth, height: buttonHeight)
            let button = UIButton(type: UIButtonType.custom)
            button.frame = frame
            button.transform = rotation90
            button.setTitle(charValue, for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.layer.cornerRadius = 3.0
            button.layer.masksToBounds = false
            button.backgroundColor = UIColor.white
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
            button.addTarget(self, action: #selector(YTScanCodeView.didClickedKeyboardButtonAction(btn:)), for: .touchUpInside)
            button.tag = 200 + arrayKeyboardButton.count
            if arrayKeyboardButton.count == 10 {
                button.setImage(UIImage.init(named: "Keyboard_Backspace"), for: .normal)
            }
            if arrayKeyboardButton.count == 21{
                button.setImage(UIImage.init(named: "rewordspace"), for: .normal)
            }
            if arrayKeyboardButton.count == 31{
                button.setImage(UIImage.init(named: "backspace"), for: .normal)
            }
            self.addSubview(button)
            buttonPosY += interval + buttonTempWidth
            arrayKeyboardButton.append(button)
        }
    }
    
    //MARK: - 虚拟键盘响应事件
    @objc func didClickedKeyboardButtonAction(btn: UIButton) {
        if btn.tag == 210//删除字符
        {
            vinCodeView.deleteBackward()
        }
        else if btn.tag == 221//光标向前移动一个位置
        {
            var range = vinCodeView.selectedRange()
            range.location = range.location - 1
            vinCodeView.setSelectedRange(range: range)
        }
        else if btn.tag == 231//光标向后移动一个位置
        {
            var range = vinCodeView.selectedRange()
            range.location = range.location + 1
            vinCodeView.setSelectedRange(range: range)
        }else{
            if let labCon = btn.titleLabel?.text{
                vinCodeView.insertText(labCon)//输入文本
            }
        }
    }
    
}

// MARK: UITextField extension
extension UITextField {
    func selectedRange() -> NSRange
    {
        let beginning = self.beginningOfDocument
        let selectedRange = self.selectedTextRange
        let selectionStart = selectedRange?.start
        let selectionEnd = selectedRange?.end
        guard let _ = selectionStart else { return NSRange.init(location: 0, length: 0)}
        guard let _ = selectionEnd else { return NSRange.init(location: 0, length: 0)}
        let location = self.offset(from: beginning, to: selectionStart!)
        let length = self.offset(from: selectionStart!, to: selectionEnd!)
        return NSRange.init(location: location, length: length)
    }
    
    func setSelectedRange(range: NSRange)
    {
        let beginning = self.beginningOfDocument
        let startPosition = self.position(from: beginning, offset: range.location)
        let endPosition = self.position(from: beginning, offset: range.location + range.length)
        guard let _ = startPosition else { return }
        guard let _ = endPosition else { return }
        let selectionRange = self.textRange(from: startPosition!, to: endPosition!)
        self.selectedTextRange = selectionRange
    }
}

// MARK: - CGFloat
public func degreesToRadians (_ angle: CGFloat) -> CGFloat {
    return (CGFloat (Double.pi) * angle) / 180.0
}

// MARK: 屏幕宽高(适配横竖屏)
public var Orientation: UIInterfaceOrientation {
    get {
        return UIApplication.shared.statusBarOrientation
    }
}

/// 屏幕宽度
public var ScreenWidth: CGFloat {
    get {
        if UIInterfaceOrientationIsPortrait(Orientation) {
            return UIScreen.main.bounds.size.width
        } else {
            return UIScreen.main.bounds.size.height
        }
    }
}

/// 屏幕高度
public var ScreenHeight: CGFloat {
    get {
        if UIInterfaceOrientationIsPortrait(Orientation) {
            return UIScreen.main.bounds.size.height
        } else {
            return UIScreen.main.bounds.size.width
        }
    }
}

