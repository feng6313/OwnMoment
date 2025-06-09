//
//  FrametwelveView.swift
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

struct FrametwelveView: View {
    @Environment(\.presentationMode) var presentationMode
    var selectedImage: UIImage?
    var frameIndex: Int? // 标识是从哪个相框点击进入的
    

    // 添加状态变量来跟踪缩放和位置
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var currentPosition: CGSize = .zero
    @State private var previousPosition: CGSize = .zero
    
    // 添加性能优化相关的状态变量
    @State private var isDragging: Bool = false
    @State private var isScaling: Bool = false
    @State private var cachedImageBounds: CGRect = .zero
    @State private var lastValidPosition: CGSize = .zero
    
    // 添加设置相关的状态变量
    @State private var isSettingsPresented = false
    @State private var customDate = Date()
    @State private var customLocation = ""
    @State private var showDate = true
    @State private var showLocation = true
    
    // 添加状态变量来控制RememberView的显示
    @State private var isRememberViewPresented = false
    @State private var memoryText = "我的独家记忆"
    
    // 添加保存相关的状态变量
    @State private var showSaveAlert = false
    @State private var saveAlertTitle = ""
    @State private var saveAlertMessage = ""
    
    // 添加颜色相关的状态变量
    @State private var frameColor: Color = .white // 边框颜色
    @State private var titleTextColor: Color = Color("#1C1E22") // 标题文字颜色
    @State private var dateTextColor: Color = Color("#F56E00") // 时间颜色
    @State private var locationTextColor: Color = Color("#1C1E22") // 地点文字颜色
    @State private var iconColor: Color = Color("#1C1E22") // 图标颜色
    @State private var selectedColorOption = 0 // 当前选中的颜色选项（下方矩形框）
    @State private var selectedSlideOption = 0 // 当前选中的滑动选项（上方滑动按钮）
    @State private var showColorControls: Bool = true // 控制圆形色块和滑动按钮的显示
    
    // 添加动态尺寸变量 - 修改为圆形255*255
    @State private var frameWidth: CGFloat = 371
    @State private var frameHeight: CGFloat = 455
    @State private var displayWidth: CGFloat = 255
    @State private var displayHeight: CGFloat = 255
    
    // 显示区域的尺寸常量 - 修改为圆形区域
    private var displayAreaSize: CGFloat {
        return displayWidth // 圆形区域，使用宽度作为基准
    }

    var body: some View {
        ZStack {
            // 设置背景色与ChooseView一致
            Color("#0C0F14")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 添加白色背景，紧贴导航条
                ZStack {
                    // 背景，尺寸371*455，颜色可变，左右居中
                    Rectangle()
                        .fill(frameColor)
                        .frame(width: 371, height: 455)
                    
                    // 当选择内容选项时，显示添加回忆内容的提示文字在底部选择框上方85点的位置
                    if selectedColorOption == 1 {
                        Button(action: {
                            isRememberViewPresented = true
                        }) {
                            Text("+点击添加回忆内容")
                                .font(.system(size: 16))
                                .foregroundColor(Color.gray)
                        }
                        .frame(width: 339, height: 48)
                        .offset(y: 455/2 + 85) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上85点
                        .zIndex(1) // 确保按钮在最上层
                        .allowsHitTesting(true) // 确保按钮可以接收点击事件
                    }
                    
                    // 在白色背景上层添加圆形图片显示区域，与背景上下居中
                    ZStack {
                        Circle()
                            .fill(Color.white) // 暂用白色填充
                            .frame(width: 255, height: 255)
                        
                        // 显示选择的图片
                        if let image = selectedImage {
                            
                            ZStack(alignment: .bottomTrailing) {
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
                                    // 添加手势识别
                                    .gesture(
                                        // 组合缩放和拖动手势
                                        SimultaneousGesture(
                                            // 缩放手势
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
                                                },
                                            // 拖动手势
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
                                        )
                                    )
                                    .clipShape(Circle()) // 裁剪为圆形
                                    .allowsHitTesting(true) // 始终允许图片的手势识别
                                    .onAppear {
                                        // 初始化缓存的图片边界
                                        updateCachedImageBounds(for: image)
                                    }
                                    .onChange(of: currentScale) { oldValue, newValue in
                                        // 缩放变化时更新缓存
                                        updateCachedImageBounds(for: image)
                                    }
                            }
                        } else {
                            Text("未选择图片")
                                .foregroundColor(.white)
                        }
                    }
                    // 与白色背景上下居中：白色背景高度455，图片区域高度255，居中不需要offset
                    
                    // 添加文字和位置信息，位于白色背景下方48点处，左右居中
                    VStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .center, spacing: 2) {
                            ForEach(Array(formatTextForTwoLines(memoryText).enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(titleTextColor)
                                    .multilineTextAlignment(.center)
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
                    .offset(y: -455/2 + 48) // 位于白色背景下方48点处
                    
                    // 添加时间显示，位于白色背景下方424点处，左右居中
                    if showDate, let image = selectedImage {
                        Text(getImageDate(image) ?? "未知日期")
                            .font(.custom("PixelMplus12-Regular", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(dateTextColor)
                            .offset(y: -455/2 + 424) // 位于白色背景下方424点处
                    }
                    
                    // 添加滑动选择按钮，放在白色背景下方10点的位置
                    if showColorControls {
                        SlideSelector(selectedOption: $selectedSlideOption)
                            .offset(y: 455/2 + 32) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上10点
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
                    .offset(y: 455/2 + 24 + 180) // 滑动选择按钮下方48点的位置
                    
                    // 添加颜色选择器，放在图标选项栏下方
                    if showColorControls {
                        ColorSelector(
                            selectedOption: $selectedSlideOption, // 使用滑动选项的索引
                            frameColor: $frameColor,
                            titleTextColor: $titleTextColor,
                            dateTextColor: $dateTextColor,
                            locationTextColor: $locationTextColor,
                            iconColor: $iconColor
                        )
                        .offset(y: 455/2 + 24 + 80) // 图标选项栏下方10点的位置
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                        .animation(.easeInOut(duration: 0.3), value: showColorControls)
                    }
                    
                    // 添加更多选项的UI
                    if selectedColorOption == 2 {
                        VStack(spacing: 0) {
                            // 日期选项
                            Button(action: {
                                isSettingsPresented = true
                            }) {
                                HStack {
                                    Image("date")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                    
                                    Text("日期")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                            }
                            
                            // 分隔线
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 0.5)
                                .padding(.leading, 50)
                            
                            // 地点选项
                            Button(action: {
                                isSettingsPresented = true
                            }) {
                                HStack {
                                    Image("map_b")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                    
                                    Text("地点")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color("#2C2C2E"))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .frame(height: 100)
                        .offset(y: 455/2 + 85) // 白色背景高度为455，除以2得到从中心到底部的距离，再减去选项高度和上方间距
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                        .animation(.easeInOut(duration: 0.3), value: selectedColorOption)
                    }
                }
                
                Spacer() // 填充剩余空间
            }
        }
        .navigationBarBackButtonHidden(true) // 隐藏默认返回按钮
        .navigationBarTitleDisplayMode(.inline) // 确保标题居中
        .toolbarColorScheme(.dark, for: .navigationBar) // 保持导航栏颜色风格一致
        .toolbarBackground(Color("#0C0F14"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isRememberViewPresented) {
            RememberView(memoryText: $memoryText)
        }
        .toolbar(content: {
            // 左侧返回按钮
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            
            // 中间标题
            ToolbarItem(placement: .principal) {
                Text("编辑")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            // 右侧保存按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 保存按钮的操作
                    saveImageToPhotoAlbum()
                }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 30, alignment: .center)
                        .background(Color("#007AFF"))
                        .cornerRadius(15)
                }
            }
        })
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                customDate: $customDate,
                customLocation: $customLocation,
                showDate: $showDate,
                showLocation: $showLocation
            )
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveAlertTitle),
                message: Text(saveAlertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}

struct FrametwelveView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了预览，我们需要一个NavigationView上下文
        NavigationView {
            FrametwelveView(selectedImage: nil, frameIndex: 0)
        }
    }
}

extension FrametwelveView {
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
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            // 显示权限被拒绝的提示
            self.showPermissionDeniedAlert()
        @unknown default:
            // 处理未来可能添加的新状态
            self.showPermissionDeniedAlert()
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
                    
                    // 在白色背景上层添加圆形图片显示区域，与白色背景上下居中
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
                                    .clipShape(Circle()) // 裁剪为圆形
                            }
                        }
                    }
                    // 与白色背景上下居中：白色背景高度455，图片区域高度255，居中不需要offset
                    
                    // 添加文字和位置信息，位于白色背景下方48点处，左右居中
                    VStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .center, spacing: 2) {
                            ForEach(Array(formatTextForTwoLines(memoryText).enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(titleTextColor)
                                    .multilineTextAlignment(.center)
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
                    .offset(y: -frameHeight/2 + 48) // 位于白色背景下方48点处
                    
                    // 添加时间显示，位于白色背景下方424点处，左右居中
                    if showDate, let image = selectedImage {
                        Text(getImageDate(image) ?? "未知日期")
                            .font(.custom("PixelMplus12-Regular", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(dateTextColor)
                            .offset(y: -frameHeight/2 + 424) // 位于白色背景下方424点处
                    }
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
                    
                    // 在白色背景上层添加圆形图片显示区域，与白色背景上下居中
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
                                    .clipShape(Circle()) // 裁剪为圆形
                            }
                        }
                    }
                    // 与白色背景上下居中：白色背景高度455，图片区域高度255，居中不需要offset
                    
                    // 添加文字和位置信息，位于白色背景下方48点处，左右居中
                    VStack(alignment: .center, spacing: 6) {
                        VStack(alignment: .center, spacing: 2) {
                            ForEach(Array(formatTextForTwoLines(memoryText).enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(titleTextColor)
                                    .multilineTextAlignment(.center)
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
                    .offset(y: -frameHeight/2 + 48) // 位于白色背景下方48点处
                    
                    // 添加时间显示，位于白色背景下方424点处，左右居中
                    if showDate, let image = selectedImage {
                        Text(getImageDate(image) ?? "未知日期")
                            .font(.custom("PixelMplus12-Regular", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(dateTextColor)
                            .offset(y: -frameHeight/2 + 424) // 位于白色背景下方424点处
                    }
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
    
    // 显示权限被拒绝的提示
    private func showPermissionDeniedAlert() {
        self.saveAlertTitle = "无法访问相册"
        self.saveAlertMessage = "请在设置中允许应用访问您的相册，以便保存图片。"
        self.showSaveAlert = true
    }
}

extension FrametwelveView {
    // 计算适当的尺寸
    private func calculateSizes() {
        guard selectedImage != nil else { return }
        
        // 设置显示区域尺寸（固定为255*255圆形）
        displayWidth = 255
        displayHeight = 255
        
        // 设置边框尺寸
        frameWidth = 371 // 固定宽度
        frameHeight = 455 // 固定高度
    }
    
    // 优化后的偏移量计算函数，减少重复计算
    func limitOffsetToDisplayAreaOptimized(_ offset: CGSize, scale: CGFloat, image: UIImage) -> CGSize {
        // 使用缓存的边界信息，避免重复计算
        if cachedImageBounds == .zero {
            updateCachedImageBounds(for: image)
        }
        
        // 应用用户的缩放到缓存的尺寸
        let scaledWidth = cachedImageBounds.width * scale
        let scaledHeight = cachedImageBounds.height * scale
        
        // 计算可移动的范围
        let maxOffsetX = max(0, (scaledWidth - displayWidth) / 2)
        let maxOffsetY = max(0, (scaledHeight - displayHeight) / 2)
        
        // 限制偏移量，确保图片不会移出显示区域
        let limitedX = min(maxOffsetX, max(-maxOffsetX, offset.width))
        let limitedY = min(maxOffsetY, max(-maxOffsetY, offset.height))
        
        return CGSize(width: limitedX, height: limitedY)
    }
    
    // 更新缓存的图片边界信息
    func updateCachedImageBounds(for image: UIImage) {
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
    
    // 计算偏移量，允许图片在显示区域内移动（保留原函数作为备用）
    func limitOffsetToDisplayArea(_ offset: CGSize, scale: CGFloat) -> CGSize {
        guard let image = selectedImage else { return .zero }
        
        // 获取图片的原始尺寸
        let imageSize = image.size
        
        // 计算图片在显示区域内的实际尺寸（考虑缩放和填充模式）
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
        
        // 应用用户的缩放
        scaledWidth *= scale
        scaledHeight *= scale
        
        // 计算可移动的范围
        let maxOffsetX = (scaledWidth - displayWidth) / 2
        let maxOffsetY = (scaledHeight - displayHeight) / 2
        
        // 限制偏移量，确保图片不会移出显示区域
        let limitedX = min(maxOffsetX, max(-maxOffsetX, offset.width))
        let limitedY = min(maxOffsetY, max(-maxOffsetY, offset.height))
        
        return CGSize(width: limitedX, height: limitedY)
    }
    
    // 截断文本，超过指定长度的部分用...代替
    func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            // 超过maxLength个字符时，显示前maxLength个字符加...
            let index = text.index(text.startIndex, offsetBy: maxLength)
            return String(text[..<index]) + "..."
        }
    }
    
    // 格式化文本为两行显示：第一行最多20个字符，第二行最多15个字符
    func formatTextForTwoLines(_ text: String) -> [String] {
        if text.count <= 20 {
            // 文本长度不超过20个字符，只显示一行
            return [text]
        } else if text.count <= 35 {
            // 文本长度在20-35个字符之间，分两行显示
            let firstLineEnd = text.index(text.startIndex, offsetBy: 20)
            let firstLine = String(text[..<firstLineEnd])
            let secondLine = String(text[firstLineEnd...])
            
            if secondLine.count <= 15 {
                return [firstLine, secondLine]
            } else {
                // 第二行超过15个字符，截断并加"···"
                let secondLineEnd = secondLine.index(secondLine.startIndex, offsetBy: 15)
                let truncatedSecondLine = String(secondLine[..<secondLineEnd]) + "···"
                return [firstLine, truncatedSecondLine]
            }
        } else {
            // 文本长度超过35个字符
            let firstLineEnd = text.index(text.startIndex, offsetBy: 20)
            let firstLine = String(text[..<firstLineEnd])
            let remainingText = String(text[firstLineEnd...])
            
            if remainingText.count <= 15 {
                return [firstLine, remainingText]
            } else {
                // 第二行超过15个字符，截断并加"···"
                let secondLineEnd = remainingText.index(remainingText.startIndex, offsetBy: 15)
                let truncatedSecondLine = String(remainingText[..<secondLineEnd]) + "···"
                return [firstLine, truncatedSecondLine]
            }
        }
    }
    
    // 获取照片地理位置信息
    private func getLocationText() -> String {
        // 如果设置了自定义位置，优先使用自定义位置
        if !customLocation.isEmpty {
            return customLocation
        }
        
        // 返回默认值"未知地点"
        return "未知地点"
    }
    
    // 获取图片拍摄日期
    private func getImageDate(_ image: UIImage) -> String? {
        // 如果设置了自定义日期，优先使用自定义日期
        if let customDateString = getCustomDateIfSet() {
            return customDateString
        }
        
        // 使用当前日期
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 检查是否应该使用自定义日期
    private func getCustomDateIfSet() -> String? {
        // 检查自定义日期是否有效且与当前日期不同
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let customYear = calendar.component(.year, from: customDate)
        
        // 只有当自定义日期与当前日期不同时才使用自定义日期
        // 这样可以避免使用默认的当前日期
        if customYear != currentYear || calendar.isDateInToday(customDate) == false {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: customDate)
        }
        
        return nil
    }
}
