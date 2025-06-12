//
//  FramethreeView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/15.
//

import SwiftUI
import Photos
import UIKit
#if canImport(AppKit)
import AppKit
#endif

struct FramethreeView: View {
    @Environment(\.presentationMode) var presentationMode
    var selectedImage: UIImage?
    var frameIndex: Int? // 标识是从哪个相框点击进入的
    
    // 添加状态变量来跟踪缩放和位置
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var currentPosition = CGSize.zero
    @State private var previousPosition = CGSize.zero
    @State private var lastValidPosition = CGSize.zero
    @State private var isDragging = false
    @State private var isScaling = false
    
    // 添加设置相关的状态变量
    @State private var customDate = Date()
    @State private var customLocation = ""
    @State private var showDate = true
    @State private var showLocation = true
    
    // 添加回忆内容相关的状态变量
    @State private var memoryText = ""
    @State private var isRememberViewPresented = false
    
    // 添加保存相关的状态变量
    @State private var showSaveAlert = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    @State private var isSettingsPresented = false
    @State private var isSettingsViewPresented = false
    @State private var showPermissionDeniedAlert = false
    
    // 添加颜色相关的状态变量
    @State private var frameColor = Color("#FFFFFF") // 默认白色
    @State private var titleTextColor = Color("#000000") // 默认黑色
    @State private var dateTextColor = Color("#000000") // 默认黑色
    @State private var locationTextColor = Color("#000000") // 默认黑色
    @State private var iconColor = Color("#000000") // 默认黑色
    
    // 添加选项相关的状态变量
    @State private var selectedColorOption = 0 // 0: 颜色, 1: 内容, 2: 更多
    @State private var selectedSlideOption = 0 // 0: 相框, 1: 标题, 2: 日期, 3: 地点, 4: 图标, 5: 用户名
    @State private var showColorControls = true // 控制是否显示颜色控制器
    
    // 添加用户信息相关的状态变量
    @State private var userName = "用户名"
    @State private var userNameColor = Color("#000000") // 默认黑色
    @State private var userIconColor = Color("#000000") // 默认黑色
    
    // 添加图片显示区域的尺寸
    private var displayWidth: CGFloat = 339
    private var displayHeight: CGFloat = 290
    
    // 添加相框尺寸
    private var frameWidth: CGFloat = 371
    private var frameHeight: CGFloat = 455
    
    // 缓存图片边界计算
    @State private var cachedImageBounds: CGRect = .zero
    
    var body: some View {
        ZStack {
            // 背景视图
            Color("#0C0F14")
                .ignoresSafeArea()
            
            // 主要内容
            VStack(spacing: 0) {
                // 添加白色背景，紧贴导航条
                ZStack {
                    frameBackgroundView
                    userInfoView
                    rememberContentButton
                    imageDisplayArea
                    socialInteractionIcons
                    bottomSelectionArea
                }
                .frame(width: 371, height: 455)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isRememberViewPresented) {
            RememberView(memoryText: $memoryText)
        }
        .sheet(isPresented: $isSettingsViewPresented) {
            SettingsView(customDate: $customDate, customLocation: $customLocation, showDate: $showDate, showLocation: $showLocation)
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(title: Text(saveAlertTitle), message: Text(saveAlertMessage), dismissButton: .default(Text("确定")))
        }
        .alert("权限被拒绝", isPresented: $showPermissionDeniedAlert) {
            Button("确定") { }
        } message: {
            Text("请在设置中允许访问相册")
        }
    }
    
    // MARK: - 子视图组件
    
    private var frameBackgroundView: some View {
        Rectangle()
            .fill(frameColor)
            .frame(width: 371, height: 455)
    }
    
    private var userInfoView: some View {
        HStack(spacing: 8) {
            // 用户头像
            Image("user")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            
            // 用户名
            Text(userName)
                .font(.system(size: 12))
                .foregroundColor(userNameColor)
            
            Spacer()
            
            // 三点图标
            Image("three points")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(userIconColor)
        }
        .padding(.horizontal, 16)
        .frame(width: 339)
        .offset(y: -455/2 + 10 + 14) // 距离背景上边缘10点
    }
    
    private var rememberContentButton: some View {
        Group {
            if selectedColorOption == 1 {
                Button(action: {
                    isRememberViewPresented = true
                }) {
                    Text("+点击添加回忆内容")
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray)
                }
                .frame(width: 339, height: 44)
                .offset(y: 455/2 + 85) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上85点
                .zIndex(1) // 确保按钮在最上层
                .allowsHitTesting(true) // 确保按钮可以接收点击事件
            }
        }
    }
    
    private var imageDisplayArea: some View {
        ZStack {
            Rectangle()
                .fill(Color.white) // 暂用白色填充
                .frame(width: 339, height: 290)
            
            // 显示选择的图片
            if let image = selectedImage {
                imageWithGesturesView(image: image)
            } else {
                Text("未选择图片")
                    .foregroundColor(.white)
            }
        }
        .offset(y: -455/2 + 48 + 290/2) // 距离背景上边缘48点
    }
    
    private func imageWithGesturesView(image: UIImage) -> some View {
        let imageView = createImageView(image: image)
        let magnificationGesture = createMagnificationGesture(image: image)
        let dragGesture = createDragGesture(image: image)
        let combinedGesture = SimultaneousGesture(magnificationGesture, dragGesture)
        
        return ZStack(alignment: .bottomTrailing) {
            imageView
                .gesture(combinedGesture)
                .onAppear {
                    initializeImageBounds(image: image)
                }
                .onChange(of: currentScale) { oldValue, newValue in
                    updateImageBounds(image: image)
                }
            
            // 添加日期显示
            if showDate {
                Text(getImageDate(image) ?? "未知日期")
                    .font(.custom("PixelMplus12-Regular", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(dateTextColor)
                    .padding([.bottom, .trailing], 10)
            }
        }
    }
    
    private func createImageView(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill() // 使用fill而不是fit，确保完全填充
            .frame(width: displayWidth, height: displayHeight)
            // 应用缩放效果
            .scaleEffect(currentScale)
            // 应用位置偏移，但限制在显示区域内
            .offset(isDragging || isScaling ? currentPosition : lastValidPosition)
            // 只在手势结束时应用动画
            .animation(isDragging || isScaling ? nil : .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: currentScale)
            .animation(isDragging || isScaling ? nil : .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: lastValidPosition)
            .clipped() // 隐藏超出显示区域的部分
            .allowsHitTesting(true) // 始终允许图片的手势识别
    }
    
    private func createMagnificationGesture(image: UIImage) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                isScaling = true
                // 限制缩放范围在1.0到5.0之间
                let newScale = min(max(previousScale * value, 1.0), 5.0)
                currentScale = newScale
            }
            .onEnded { value in
                isScaling = false
                // 保存当前缩放值作为下次手势的基准
                previousScale = currentScale
                
                // 如果缩放小于1.1，平滑地恢复到1.0
                if currentScale < 1.1 {
                    currentScale = 1.0
                    previousScale = 1.0
                }
                
                // 重新计算并限制位置
                let correctedPosition = limitOffsetToDisplayAreaOptimized(currentPosition, scale: currentScale, image: image)
                currentPosition = correctedPosition
                previousPosition = correctedPosition
                lastValidPosition = correctedPosition
            }
    }
    
    private func createDragGesture(image: UIImage) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                // 计算新的位置
                let newPosition = CGSize(
                    width: previousPosition.width + value.translation.width,
                    height: previousPosition.height + value.translation.height
                )
                currentPosition = newPosition
            }
            .onEnded { value in
                isDragging = false
                // 保存当前位置作为下次手势的基准
                previousPosition = currentPosition
                
                // 检查并修正边界，添加回弹效果
                let correctedPosition = limitOffsetToDisplayAreaOptimized(currentPosition, scale: currentScale, image: image)
                currentPosition = correctedPosition
                previousPosition = correctedPosition
                lastValidPosition = correctedPosition
            }
    }
    
    private func initializeImageBounds(image: UIImage) {
        // 初始化缓存的图片边界
        if cachedImageBounds == .zero {
            let imageSize = image.size
            let imageAspectRatio = imageSize.width / imageSize.height
            let displayAreaAspectRatio = displayWidth / displayHeight
            
            var scaledWidth: CGFloat
            var scaledHeight: CGFloat
            
            if imageAspectRatio > displayAreaAspectRatio {
                // 图片较宽，高度适应显示区域
                scaledHeight = displayHeight
                scaledWidth = scaledHeight * imageAspectRatio
            } else {
                // 图片较高，宽度适应显示区域
                scaledWidth = displayWidth
                scaledHeight = scaledWidth / imageAspectRatio
            }
            
            cachedImageBounds = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        }
    }
    
    private func updateImageBounds(image: UIImage) {
        // 缩放变化时更新缓存
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let displayAreaAspectRatio = displayWidth / displayHeight
        
        var scaledWidth: CGFloat
        var scaledHeight: CGFloat
        
        if imageAspectRatio > displayAreaAspectRatio {
            // 图片较宽，高度适应显示区域
            scaledHeight = displayHeight
            scaledWidth = scaledHeight * imageAspectRatio
        } else {
            // 图片较高，宽度适应显示区域
            scaledWidth = displayWidth
            scaledHeight = scaledWidth / imageAspectRatio
        }
        
        cachedImageBounds = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
    }
    

    
    // MARK: - 子视图组件
}

extension FramethreeView {
    // 保存图片到相册
    func saveImageToPhotoAlbum() {
        #if canImport(UIKit)
        // 检查相册访问权限
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            // 已授权，继续保存图片
            proceedWithSavingImage()
        case .notDetermined:
            // 请求授权
            PHPhotoLibrary.requestAuthorization { [self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.proceedWithSavingImage()
                    } else {
                        self.showPermissionDeniedAlertAction()
                    }
                }
            }
        case .denied, .restricted:
            // 显示权限被拒绝的提示
            self.showPermissionDeniedAlertAction()
        @unknown default:
            // 处理未来可能添加的新状态
            self.showPermissionDeniedAlertAction()
        }
        #elseif canImport(AppKit)
        // 在macOS上实现保存功能
        proceedWithSavingImage()
        #endif
    }
    
    // 实际保存图片的方法
    private func proceedWithSavingImage() {
        #if canImport(UIKit)
        if #available(iOS 16.0, *) {
            // 创建一个与白色背景大小相同的上下文
            let renderer = ImageRenderer(content:
                ZStack {
                    // 背景，使用动态尺寸
                    Rectangle()
                        .fill(frameColor)
                        .frame(width: frameWidth, height: frameHeight)
                    
                    // 在白色背景上层添加图片显示区域，距离白色背景边缘16点
                    ZStack {
                        if let image = selectedImage {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill() // 使用fill而不是fit，确保完全填充
                                    .frame(width: displayWidth, height: displayHeight)
                                    // 应用缩放效果
                                    .scaleEffect(currentScale)
                                    // 应用位置偏移，使用最新的位置计算
                                    .offset(lastValidPosition)
                                    .clipped() // 隐藏超出显示区域的部分
                                
                                // 添加日期显示
                                if showDate {
                                    Text(getImageDate(image) ?? "未知日期")
                                        .font(.custom("PixelMplus12-Regular", size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(dateTextColor)
                                        .padding([.bottom, .trailing], 10)
                                }
                            }
                        }
                    }
                    .frame(width: displayWidth, height: displayHeight)
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            let formattedLines = formatTextForTwoLines(memoryText)
                            let enumeratedLines = Array(formattedLines.enumerated())
                            ForEach(enumeratedLines, id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(titleTextColor)
                            }
                        }
                        
                        if showLocation {
                            HStack(spacing: 2) {
                                Image("map_s")
                                    .renderingMode(.template)
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(iconColor)
                                
                                Text(getLocationText())
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(locationTextColor)
                            }
                        }
                    }
                    .padding(.top, 350) // 向下移动350点，与设置界面保持一致
                    .padding(.leading, 0) // 移除左边距
                    .frame(width: displayWidth, alignment: .leading) // 与显示区宽度一致
                }
                .frame(width: frameWidth, height: frameHeight)
            )
            
            // 配置渲染器 - 根据原始图片尺寸调整缩放因子
            if let image = selectedImage {
                // 计算适当的缩放因子，使输出图片尽可能接近原始尺寸
                let originalWidth = image.size.width
                let originalHeight = image.size.height
                let scaleFactorWidth = originalWidth / frameWidth
                let scaleFactorHeight = originalHeight / frameHeight
                let scaleFactor = max(2.0, min(scaleFactorWidth, scaleFactorHeight, 4.0)) // 限制在2.0-4.0之间
                
                renderer.scale = scaleFactor
            } else {
                renderer.scale = 2.0 // 默认缩放因子
            }
            
            // 获取渲染后的图片
            if let uiImage = renderer.uiImage {
                // 保存到相册
                // 使用Photos框架保存图片
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                } completionHandler: { [self] success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.saveAlertTitle = "保存成功"
                            self.saveAlertMessage = "图片已成功保存到相册"
                        } else if let error = error {
                            self.saveAlertTitle = "保存失败"
                            self.saveAlertMessage = error.localizedDescription
                        }
                        self.showSaveAlert = true
                    }
                }
            } else {
                saveAlertTitle = "保存失败"
                saveAlertMessage = "无法生成图片"
                showSaveAlert = true
            }
        } else {
            // iOS 15兼容处理
            saveAlertTitle = "功能不可用"
            saveAlertMessage = "此功能需要iOS 16.0或更高版本"
            showSaveAlert = true
        }
        #elseif canImport(AppKit)
        // macOS实现
        if #available(macOS 13.0, *) {
            // 创建一个与白色背景大小相同的上下文
            let renderer = ImageRenderer(content:
                ZStack {
                    // 背景，使用动态尺寸
                    Rectangle()
                        .fill(frameColor)
                        .frame(width: frameWidth, height: frameHeight)
                    
                    // 在白色背景上层添加图片显示区域，距离白色背景边缘16点
                    ZStack {
                        if let image = selectedImage {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill() // 使用fill而不是fit，确保完全填充
                                    .scaleEffect(currentScale)
                                    // 应用位置偏移，使用最新的位置计算
                                    .offset(lastValidPosition)
                                    .clipped() // 隐藏超出显示区域的部分
                                
                                // 添加日期显示
                                if showDate {
                                    Text(getImageDate(image) ?? "未知日期")
                                        .font(.custom("PixelMplus12-Regular", size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(dateTextColor)
                                        .padding([.bottom, .trailing], 10)
                                }
                            }
                        }
                    }
                    .frame(width: displayWidth, height: displayHeight)
                    
                    // 文字信息在保存时不需要显示
                }
                .frame(width: frameWidth, height: frameHeight)
            )
            
            // 配置渲染器 - 根据原始图片尺寸调整缩放因子
            if let image = selectedImage {
                // 计算适当的缩放因子，使输出图片尽可能接近原始尺寸
                let originalWidth = image.size.width
                let originalHeight = image.size.height
                let scaleFactorWidth = originalWidth / frameWidth
                let scaleFactorHeight = originalHeight / frameHeight
                let scaleFactor = max(2.0, min(scaleFactorWidth, scaleFactorHeight, 4.0)) // 限制在2.0-4.0之间
                
                renderer.scale = scaleFactor
            } else {
                renderer.scale = 2.0 // 默认缩放因子
            }
            
            // 获取渲染后的图片
            if let nsImage = renderer.nsImage {
                // 在macOS上实现保存功能
                saveAlertTitle = "保存成功"
                saveAlertMessage = "图片已成功保存"
                showSaveAlert = true
            } else {
                saveAlertTitle = "保存失败"
                saveAlertMessage = "无法生成图片"
                showSaveAlert = true
            }
        } else {
            // macOS 13以下版本兼容处理
            saveAlertTitle = "功能不可用"
            saveAlertMessage = "此功能需要macOS 13.0或更高版本"
            showSaveAlert = true
        }
        #endif
    }
    

    
    // 限制偏移量到显示区域内的优化方法
    private func limitOffsetToDisplayAreaOptimized(_ offset: CGSize, scale: CGFloat, image: UIImage) -> CGSize {
        let scaledImageWidth = cachedImageBounds.width * scale
        let scaledImageHeight = cachedImageBounds.height * scale
        
        let maxOffsetX = max(0, (scaledImageWidth - displayWidth) / 2)
        let maxOffsetY = max(0, (scaledImageHeight - displayHeight) / 2)
        
        let clampedX = max(-maxOffsetX, min(maxOffsetX, offset.width))
        let clampedY = max(-maxOffsetY, min(maxOffsetY, offset.height))
        
        return CGSize(width: clampedX, height: clampedY)
    }
    
    // 获取图片日期
    private func getImageDate(_ image: UIImage) -> String? {
        return getCustomDateIfSet()
    }
    
    // 获取自定义日期
    private func getCustomDateIfSet() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: customDate)
    }
    
    // 格式化文本为两行
    private func formatTextForTwoLines(_ text: String) -> [String] {
        if text.isEmpty {
            return ["我的独家记忆"]
        }
        
        let maxLength = 20
        if text.count <= maxLength {
            return [text]
        } else {
            let firstLine = String(text.prefix(maxLength))
            let secondLine = String(text.dropFirst(maxLength))
            return [firstLine, secondLine]
        }
    }
    
    // 获取位置文本
    private func getLocationText() -> String {
        return customLocation.isEmpty ? "未设置位置" : customLocation
    }
    
    // 更新缓存的图片边界
    private func updateCachedImageBounds() {
        guard let image = selectedImage else { return }
        updateImageBounds(image: image)
    }
    
    // 显示权限被拒绝的提示
    private func showPermissionDeniedAlertAction() {
        showPermissionDeniedAlert = true
    }
    
    private var socialInteractionIcons: some View {
        HStack {
            // 左侧三个图标
            HStack(spacing: 12) {
                // 心形图标（不可修改颜色）
                Image("heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                
                // 评论图标
                Image("comment")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .foregroundColor(iconColor)
                
                // 分享图标
                Image("share")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .foregroundColor(iconColor)
            }
            
            Spacer()
            
            // 收藏图标（右侧）
            Image("collect")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .foregroundColor(iconColor)
        }
        .padding(.horizontal, 16)
        .frame(width: 339)
        .offset(y: {
            let baseOffset = -455.0/2
            let additionalOffset = 48.0 + 290.0 + 12.0 + 13.0
            return baseOffset + additionalOffset
        }())
    }
    
    private var bottomSelectionArea: some View {
        VStack(spacing: 0) {
            // 添加图片下方的文字信息
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    let formattedLines = formatTextForTwoLines(memoryText)
                    let enumeratedLines = Array(formattedLines.enumerated())
                    ForEach(enumeratedLines, id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(titleTextColor)
                    }
                }
                
                if showLocation {
                    HStack(spacing: 2) {
                        Image("map_s")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(iconColor)
                        
                        Text(getLocationText())
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(locationTextColor)
                    }
                }
            }
            .padding(.top, 350) // 向下移动350点
            .padding(.leading, 0) // 移除左边距
            .frame(width: 339, alignment: .leading) // 与显示区宽度一致
            
            // 添加滑动选择按钮，放在白色背景下方10点的位置
            if showColorControls {
                SlideSelector(selectedOption: $selectedSlideOption)
                    .offset(y: 32) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上10点
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                    .animation(.easeInOut(duration: 0.3), value: showColorControls)
            }
            
            // 添加图标选项栏，放在滑动选择按钮下方
            HStack(spacing: 0) {
                Spacer(minLength: 12) // 左侧距离屏幕24点
                
                // 颜色选项
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedColorOption = 0
                        showColorControls = true // 显示圆形色块和滑动按钮
                    }
                }) {
                    ZStack {
                        // 圆角矩形框
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("#1C1E22"))
                            .frame(width: 107, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(selectedColorOption == 0 ? Color.white : Color("#3E3E3E"), lineWidth: 2)
                            )
                        
                        // 图标和文字
                        VStack(spacing: 5) {
                            Image("color")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("颜色")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(selectedColorOption == 0) // 当已选中时禁用点击反馈
                
                Spacer() // 中间自动分配空间
                
                // 文字选项
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedColorOption = 1
                        showColorControls = false // 隐藏圆形色块和滑动按钮
                    }
                }) {
                    ZStack {
                        // 圆角矩形框
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("#1C1E22"))
                            .frame(width: 107, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(selectedColorOption == 1 ? Color.white : Color("#3E3E3E"), lineWidth: 2)
                            )
                        
                        // 图标和文字
                        VStack(spacing: 5) {
                            Image("word")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("内容")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(selectedColorOption == 1) // 当已选中时禁用点击反馈
                
                Spacer() // 中间自动分配空间
                
                // 更多选项
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedColorOption = 2
                        showColorControls = false // 隐藏圆形色块和滑动按钮
                    }
                }) {
                    ZStack {
                        // 圆角矩形框
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color("#1C1E22"))
                            .frame(width: 107, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(selectedColorOption == 2 ? Color.white : Color("#3E3E3E"), lineWidth: 2)
                            )
                        
                        // 图标和文字
                        VStack(spacing: 5) {
                            Image("more")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("更多")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(selectedColorOption == 2) // 当已选中时禁用点击反馈
                
                Spacer(minLength: 12) // 右侧距离屏幕24点
            }
            .padding(.top, 20) // 与滑动选择按钮保持一定距离
            
            // 根据选择的选项显示不同的控制器
            if selectedColorOption == 0 && showColorControls {
                // 颜色选择器
                ColorSelector(selectedOption: $selectedSlideOption, frameColor: $frameColor, titleTextColor: $titleTextColor, dateTextColor: $dateTextColor, locationTextColor: $locationTextColor, iconColor: $iconColor, userNameColor: $userNameColor)
                    .padding(.top, 20)
            } else if selectedColorOption == 2 {
                // 更多选项（日期和地点）
                VStack(spacing: 20) {
                    // 日期选项
                    HStack {
                        Text("日期")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            isSettingsViewPresented = true
                        }) {
                            Text("设置")
                                .font(.system(size: 14))
                                .foregroundColor(Color("#007AFF"))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // 地点选项
                    HStack {
                        Text("地点")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            isSettingsViewPresented = true
                        }) {
                            Text("设置")
                                .font(.system(size: 14))
                                .foregroundColor(Color("#007AFF"))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer() // 填充剩余空间
                }
                .padding(.top, 20)
            }
        }
    }

}



#Preview {
    FramethreeView()
}
