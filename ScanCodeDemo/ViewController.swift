//
//  ViewController.swift
//  ScanCodeDemo
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    fileprivate var label_Type: UILabel! //类型
    fileprivate var label_Content: UILabel! //扫码结果
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initMainView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension ViewController{
    
    @objc func codeScan() {
        
        let controller = YTScanCodeViewController()
        present(controller, animated: true, completion: nil)
        controller.setBackClosure { [unowned self] (type, code) -> Void in
            self.label_Content.text = "code: \(code)"
            if type == "vin"{
                self.label_Type.text = "类型: VIN"
            }else if type == "oem"{
                 self.label_Type.text = "类型: 二维码"
            }
        }
        
    }
    
}

// MARK: UI
extension ViewController{
    
    func initMainView() {
        
        let btn = UIButton.init(type: .custom)
        btn.setTitle("扫码", for: .normal)
        btn.setTitleColor(UIColor.orange, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.orange.cgColor
        btn.addTarget(self, action: #selector(codeScan), for: .touchUpInside)
        view.addSubview(btn)
        btn.snp.makeConstraints { (make) in
            make.left.equalTo(13)
            make.right.equalTo(-13)
            make.top.equalTo(200)
            make.height.equalTo(50)
        }
        
        label_Type = createCustomLabel(content: "类型: ")
        view.addSubview(label_Type)
        label_Type.snp.makeConstraints { (make) in
            make.left.right.equalTo(btn)
            make.top.equalTo(btn.snp.bottom).offset(50)
            make.height.equalTo(25)
        }
        
        label_Content = createCustomLabel(content: "code: ")
        view.addSubview(label_Content)
        label_Content.snp.makeConstraints { (make) in
            make.left.right.height.equalTo(label_Type)
            make.top.equalTo(label_Type.snp.bottom).offset(20)
        }
        
    }
    
    func createCustomLabel(content: String) -> UILabel {
        let label = UILabel()
        label.text = content
        label.textColor = UIColor.gray
        label.font = UIFont.systemFont(ofSize: 15)
        label.sizeToFit()
        return label
    }
    
}

