//
//  OwnMomentApp.swift
//  OwnMoment
//
//  Created by feng on 2025/5/14.
//

import SwiftUI
import Photos
import CoreText
import CoreGraphics

@main
struct OwnMomentApp: App {
    init() {
        // 在应用启动时请求相册访问权限
        PHPhotoLibrary.requestAuthorization { status in
            // 只是预先请求权限，实际处理在使用时进行
        }
        
        // 注册自定义字体
        registerCustomFonts()
    }
    
    // 注册自定义字体的方法
    private func registerCustomFonts() {
        // 获取字体文件的URL
        guard let fontURL = Bundle.main.url(forResource: "PixelMplus12-Regular", withExtension: "ttf") else {
            print("无法找到字体文件")
            return
        }
        
        // 使用推荐的新API注册字体
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            print("注册字体失败: \(error?.takeRetainedValue() ?? "未知错误" as! CFError)")
        } else {
            print("成功注册字体: PixelMplus12-Regular")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ChooseView()
        }
    }
}
