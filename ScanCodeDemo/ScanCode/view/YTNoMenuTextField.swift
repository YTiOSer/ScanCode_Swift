//
//  YTNoMenuTextField.swift
//  ScanCodeDemo
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import UIKit

class YTNoMenuTextField: UITextField {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

}
