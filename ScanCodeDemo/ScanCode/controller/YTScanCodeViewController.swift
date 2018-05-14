//
//  YTScanCodeViewController.swift
//  ScanCodeDemo
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

typealias GetVinOrOemCode = (String, String) -> Void   //定义闭包传递选中的分类信息
typealias getCropImageClosure = (UIImage) -> Void

class YTScanCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate{

    // AVCaptureSession 是input 与 output 的桥梁，它协调input 到  output的数据传输
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var stillImageOutput : AVCaptureStillImageOutput?
    var captureView: UIView!
    var qrcodeView: YTScanCodeView!
    fileprivate var timer: Timer?
    fileprivate var getVinOrOemCode:GetVinOrOemCode?           //接收上个页面穿过来的闭包
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initCapture()
        setupCaptureView()
        if let goodSession = captureSession {
            goodSession.startRunning()    // 启动
            timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(YTScanCodeViewController.scrollScanAction), userInfo: nil, repeats: true)
        }
    }
    
    // 隐藏状态栏
    override var prefersStatusBarHidden: Bool{
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: 逻辑处理
extension YTScanCodeViewController{
    
    func setBackClosure(code: @escaping GetVinOrOemCode) {
        getVinOrOemCode = code
    }
    
    // 定时器控制扫描控件
    @objc func scrollScanAction() {
        qrcodeView.scrollLabel.isHidden = !qrcodeView.scanButton.isSelected
        let qrcodeViewYOffset = kScreenW * 0.75
        qrcodeView.scrollLabel.snp.updateConstraints { (make) -> Void in
            // error,因为supdate只能更新原有约束的值,并不能加入新的约束
            // make.bottom.equalTo(self.qrcodeView.codeView.snp_bottom).offset(-10)
            make.top.equalTo(self.qrcodeView.codeView.snp.top).offset(qrcodeViewYOffset - 5)
            make.centerX.equalTo(self.qrcodeView.codeView.snp.centerX)
            make.width.equalTo(self.qrcodeView.codeView.snp.width)
            make.height.equalTo(2)
        }
        UIView.animate(withDuration: 1.9, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }) { (_) -> Void in
            self.qrcodeView.scrollLabel.snp.updateConstraints { (make) -> Void in
                make.top.equalTo(self.qrcodeView.codeView.snp.top).offset(5)
            }
        }
    }
    
    func cropImageVC(_  img: UIImage) {
        //在这里可对图片进行裁剪等操作, 然后使用如百度OCR 慧视等第三方识别图片
        //裁剪可参考我的另一篇文章 https://github.com/YTiOSer/CropImage
        self.getVinOrOemCode!("vin", "图片识别需要使用第三方工具,这里给出入口")
    }
    
    // MARK:
    func fromAlbum() {
        //判断设置是否支持图片库
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            //初始化图片控制器
            let picker = UIImagePickerController()
            //设置代理
            picker.delegate = self          //指定图片控制器类型
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            //设置是否允许编辑
            picker.allowsEditing = false
            
            //弹出控制器，显示界面
            self.present(picker, animated: true, completion: {
                () -> Void in
            })
        }else{
            print("读取相册错误")
        }
    }
    
}

// MARK: 捕获 Capture
extension YTScanCodeViewController{
    
    // 初始化视频捕获
    private func initCapture() {
        // 代表抽象的硬件设备,这里传入video
        let captureDevice = AVCaptureDevice.default(for: .video)
        // 这里代表输入设备（可以是它的子类），它配置抽象硬件设备的ports。
        var captureInput:AVCaptureDeviceInput?
        if captureDevice == nil{return}
        do {
            captureInput = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureDeviceInput
        } catch let error as NSError {
            print(error)
            return
        }
        //  input和output的桥梁,它协调着intput到output的数据传输.(见字意,session-会话)
        captureSession = AVCaptureSession()
        if kScreenH < 500 {
            captureSession!.sessionPreset = .vga640x480//AVCaptureSessionPreset640x480
        }else{
            captureSession!.sessionPreset = AVCaptureSession.Preset.high
        }
        captureSession!.addInput(captureInput!)
        // 限制扫描区域http://blog.csdn.net/lc_obj/article/details/41549469
        let windowSize:CGSize = UIScreen.main.bounds.size;
        let scanSize:CGSize = CGSize(width: windowSize.width*3/4, height: windowSize.width*3/4)
        var scanRect:CGRect = CGRect.init(x: (windowSize.width-scanSize.width)/2, y: (windowSize.height-scanSize.height)/2 - 45, width: scanSize.width, height: scanSize.height)
        //计算rectOfInterest 注意x,y交换位置
        scanRect = CGRect(x: scanRect.origin.y/windowSize.height, y: scanRect.origin.x/windowSize.width, width: scanRect.size.height/windowSize.height, height: scanRect.size.width/windowSize.width)
        // 输出流 它代表输出数据，管理着输出到一个movie或者图像。
        let captureMetadataOutput = AVCaptureMetadataOutput()
        //设置可探测区域
        captureMetadataOutput.rectOfInterest = scanRect
        captureSession!.addOutput(captureMetadataOutput)
        // 添加的队列按规定必须是串行
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // 指定信息类型,QRCode
        captureMetadataOutput.metadataObjectTypes = [.ean8, .ean13, .code39, .code93, .code128, .qr]
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput!.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        captureSession!.addOutput(stillImageOutput!)
        // 用这个预览图层和图像信息捕获会话(session)来显示视频
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer!.frame = CGRect(x: 0, y: 0, width: kScreenW, height: kScreenH)
        view.layer.addSublayer(videoPreviewLayer!)
    }
    
    // 关闭捕获
    fileprivate func stopCapture() {
        if captureSession != nil {
            captureSession!.stopRunning()
            captureView.removeFromSuperview()
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if qrcodeView.currentScanMode != ScanModelState.kScanDimensionCode {
            return ;
        }
        if metadataObjects == nil || metadataObjects.count == 0 {
            captureView!.frame = CGRect.zero
            return
        }
        // 刷取出来的数据
        for metadataObject in metadataObjects {
            if metadataObject.type == .qr || metadataObject.type == .ean8 || metadataObject.type == .ean13 || metadataObject.type == .code39 || metadataObject.type == .code93 || metadataObject.type == .code128 {
                let metadata = metadataObject as? AVMetadataMachineReadableCodeObject
                // 元数据对象就会被转化成图层的坐标
                let codeCoord = videoPreviewLayer?.transformedMetadataObject(for: metadata!) as? AVMetadataMachineReadableCodeObject
                if codeCoord != nil{
                    captureView?.frame = codeCoord!.bounds
                }
                if metadata?.stringValue != nil {
                    self.captureSession?.stopRunning()
                    self.qrcodeView.removeFromSuperview()
                    self.stopCapture()
                    self.dismiss(animated: true, completion: nil)
                    self.getVinOrOemCode!("oem", metadata!.stringValue!)
                }
            }
        }
    }
    
    // MARK: 处理拍照
    private func didPressTakePhoto(){
        if let videoConnection = stillImageOutput?.connection(with: .video){
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {
                (sampleBuffer, error) in
                if sampleBuffer != nil {
                    self.stopCapture()
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    let dataProvider  = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    var captureImage = UIImage( cgImage: cgImageRef!)
                    captureImage = captureImage.imageByRotate(degreesToRadians(-90.0), true)!
                    var f: CGRect  = CGRect.zero
                    let scale = captureImage.size.height / kScreenH;
                    let w = self.qrcodeView.codeView.frame.width * scale;
                    let h = self.qrcodeView.codeView.frame.height * scale;
                    //big
                    let w2 = captureImage.size.width;
                    let h2 = captureImage.size.height;
                    f.origin.y = (h2 - h) / 2.0;
                    f.origin.x = (w2-w)/2.0;
                    f.size.height = h;
                    f.size.width  = w;
                    let image = captureImage.cropWithCropRect(f)
                    self.qrcodeView.imageClipView.image = image
                    if self.qrcodeView.imageClipView.isHidden == false
                    {
                        let img = self.qrcodeView.imageClipView.image
                        if self.qrcodeView.imageClipView.image != nil
                        {
                            //第三方识别图片
                            self.getVinOrOemCode!("vin", "图片识别需要使用第三方工具,这里给出入口")
                        }
                    }
                }
            })
        }
    }
    
}

// MARK: UI
extension YTScanCodeViewController{
    
    // MARK: - View Setup
    private func setupCaptureView() {
        // 创建系统自动捕获框
        captureView = {
            let captureView = UIView()
            captureView.layer.borderColor = UIColor.green.cgColor
            captureView.layer.borderWidth = 2
            self.view.addSubview(captureView)
            self.view.bringSubview(toFront: captureView)
            return captureView
        }()
        
        // 扫一扫的图片
        qrcodeView = {
            let codeView = YTScanCodeView(frame: CGRect.zero)
            weak var weakSelf = self
            codeView.didClickedBackButtonClosure = {
                weakSelf!.stopCapture()
                weakSelf!.qrcodeView.removeFromSuperview()
                weakSelf!.dismiss(animated: true, completion: nil)
            }
            codeView.didClickedPhonoButtonClosure = {
                weakSelf!.didPressTakePhoto()
            }
            codeView.didClickedRemakeButtonClosure = {
                if let session = weakSelf!.captureSession
                {
                    session.startRunning()
                    weakSelf!.captureView.removeFromSuperview()
                    weakSelf!.qrcodeView.resetButtonTitle()//清空原来识别的按钮上的文字
                }
            }
            //  确认
            codeView.didClickedOKVinCodeButtonClosure = {(vidCode) -> Void in
                weakSelf!.qrcodeView.removeFromSuperview()
                weakSelf!.stopCapture()
                weakSelf!.dismiss(animated: true, completion: nil)
                weakSelf!.getVinOrOemCode!("vin", vidCode)
            }
            
            self.view.addSubview(codeView)
            codeView.frame = CGRect(x: 0, y: 0, width: kScreenW, height: kScreenH)//self.view.frame
            
            //从相册中选择图像
            codeView.didClickedPhotoAlbumButtonClosure = {
                weakSelf!.stopCapture()
                weakSelf!.fromAlbum()
            }
            
            return codeView
        }()
        
    }
    
}

// MARK: UIImagePickerControllerDelegate
extension YTScanCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    //选择图片成功后代理
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        //查看info对象
        print(info)
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        //图片控制器退出
        picker.dismiss(animated: true, completion: {
            () -> Void in
            
        })
        self.cropImageVC(image)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController)  {
        
        picker.dismiss(animated: true, completion: {
            () -> Void in
            
        })
        captureSession!.startRunning()
    }
    
}





