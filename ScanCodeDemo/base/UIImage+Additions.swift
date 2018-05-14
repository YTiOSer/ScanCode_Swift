//
//  UIImage+Additions.swift
//  UIViewDemo
//
//  Created by YTiOSer on 18/5.
//  Copyright © 2018 YTiOSer. All rights reserved.
//

import Foundation
import UIKit


extension UIImage {
    
    // MARK: - 裁剪给定得区域
    /// 裁剪给定得区域
    public func cropWithCropRect( _ crop: CGRect) -> UIImage?
    {
        let cropRect = CGRect(x: crop.origin.x * self.scale, y: crop.origin.y * self.scale, width: crop.size.width * self.scale, height: crop.size.height *  self.scale)
        
        if cropRect.size.width <= 0 || cropRect.size.height <= 0 {
            return nil
        }
        var image:UIImage?
        autoreleasepool{
            let imageRef: CGImage?  = self.cgImage!.cropping(to: cropRect)
            if let imageRef = imageRef {
                image = UIImage(cgImage: imageRef)
            }
        }
        return image
    }
    
    func imageByApplayingAlpha(_ alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let area = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.scaleBy(x: 1, y: -1)
        context?.translateBy(x: 0, y: -area.height)
        context?.setBlendMode(.multiply)
        context?.setAlpha(alpha)
        context?.draw(self.cgImage!, in: area)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
    
    // MARK: - 旋转
    public func imageByRotate(_ radians: CGFloat, _ fitSize: Bool) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        let width: Int = cgImage.width
        let height: Int = cgImage.height
        let newRect: CGRect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)).applying(fitSize ? CGAffineTransform(rotationAngle: radians) : CGAffineTransform.identity)
        var resultImage: UIImage?
        autoreleasepool {
            let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
            if let context = CGContext(data: nil, width: Int(newRect.size.width), height: Int(newRect.size.height),bitsPerComponent: 8,bytesPerRow: Int(newRect.size.width * 4), space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) {
                context.setShouldAntialias(true)
                context.setAllowsAntialiasing(true)
                context.interpolationQuality = CGInterpolationQuality.high;
                context.translateBy(x: +(newRect.size.width * 0.5), y: +(newRect.size.height * 0.5))
                context.rotate(by: radians)
                context.draw(self.cgImage!, in: CGRect(x: -(CGFloat(width) * 0.5), y: -(CGFloat(height) * 0.5), width: CGFloat(width), height: CGFloat(height)))
                if let imgRef: CGImage = context.makeImage() {
                    resultImage = UIImage(cgImage: imgRef)
                }
            }
        }
        return resultImage;
    }
    
    //MARK: -   按比例裁剪图片
    func scaleToSize(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
    
    /// 按比例减少尺寸
    ///
    /// - Parameter sz: 原始图像尺寸.
    /// - Parameter limit:目标尺寸.
    /// - Returns: 函数按比例返回缩小后的尺寸
    /// - Complexity: O(*n*)
    
    func reduceSize(_ sz: CGSize, _ limit: CGFloat) -> CGSize {
        let maxPixel = max(sz.width, sz.height)
        guard maxPixel > limit else {
            return sz
        }
        var resSize: CGSize!
        let ratio = sz.height / sz.width;
        
        if (sz.width > sz.height) {
            resSize = CGSize(width:limit, height:limit*ratio);
        } else {
            resSize = CGSize(width:limit/ratio, height:limit);
        }
        
        return resSize;
    }
    
    // MARK: - 图片缩放
    /// 按比例减少给定图像的尺寸
    ///
    ///     eg:
    ///     压缩方式一：最大边不超过某个值等比例压缩
    ///     let px_1000_img = oldImg?.scaleImage(1000.0)
    ///     let px_1000_data = UIImageJPEGRepresentation(px_1000_img!, 0.7)
    ///     tv.text.append("最大边不超过1000PX的大小 \(M(Double(px_1000_data!.count))) M \n")
    ///     tv.text.append("最大边不超过1000PX宽度 \(String(describing: px_1000_img?.size.width))\n")
    ///     tv.text.append("最大边不超过1000PX高度 \(String(describing: px_1000_img?.size.height))\n\n")
    ///     tv.text.append("-------------------------------\n")
    ///
    /// - Parameter maxSideLength: 缩小后的尺寸.
    ///
    /// - Returns: 函数按比例返回缩小后的图像
    func scaleImage(_ maxSideLength: CGFloat) -> UIImage {
        guard  size.width > maxSideLength || size.height > maxSideLength else {
            return self
        }
        let imgSize = reduceSize(size, maxSideLength)
        var img: UIImage!
        // 1 代表1X
        UIGraphicsBeginImageContextWithOptions(imgSize, true, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: imgSize.width, height: imgSize.height), blendMode: .normal, alpha: 1.0)
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return img
    }
    // MARK: - 图片压缩
    /// 图片压缩
    ///
    ///     eg:
    ///     oldImg?.compressImage(1024*1024*1, 1000.0, {(data) in
    ///     let img = UIImage(data: data)
    ///     tv.text.append("图片最大值不超过最大边1M 以及 最大边不超过1000PX的大小 \(self.M(Double((data.count)))) M\n")
    ///     tv.text.append("图片最大值不超过最大边1M 以及 最大边不超过1000PX的宽度 \(img!.size.width)\n")
    ///     tv.text.append("图片最大值不超过最大边1M 以及 最大边不超过1000PX的高度 \(img!.size.height)\n\n")
    ///     tv.text.append("-------------------------------\n")
    ///     })
    ///
    /// - Parameter limitSize:限制图像的大小.
    /// - Parameter maxSideLength: 缩小后的尺寸.
    /// - Parameter completion: 闭包回调.
    /// - Returns: 函数按比例返回压缩后的图像
    func compressImage( _ limitSize: Int, _ maxSideLength: CGFloat, _ completion: @escaping (_ dataImg: Data)->Void ) {
        guard limitSize>0 || maxSideLength>0 else {
            return
        }
        //weak var weakSelf = self
        let compressQueue = DispatchQueue(label: "image_compress_queue")
        compressQueue.async {
            var quality = 0.7
            //let img = weakSelf?.scaleImage(maxSideLength)
            let img = self.scaleImage(maxSideLength)
            var imageData = UIImageJPEGRepresentation(img, CGFloat(quality) )
            guard imageData != nil else { return }
            if (imageData?.count)! <= limitSize {
                DispatchQueue.main.async(execute: {//在主线程里刷新界面
                    completion(imageData!)
                })
                return
            }
            
            repeat {
                autoreleasepool {
                    imageData = UIImageJPEGRepresentation(img, CGFloat(quality))
                    quality = quality-0.05
                }
            } while ((imageData?.count)! > limitSize);
            DispatchQueue.main.async(execute: {//在主线程里刷新界面
                completion(imageData!)
            })
        }
    }
}
