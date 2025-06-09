//
//  FramefiveView.swift
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

struct FramefiveView: View {
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
    
    // 添加动态尺寸变量
    @State private var frameWidth: CGFloat = 371
    @State private var frameHeight: CGFloat = 455
    @State private var displayWidth: CGFloat = 371
    @State private var displayHeight: CGFloat = 355
    
    // 显示区域的尺寸常量 - 将其改为计算属性
    private var displayAreaWidth: CGFloat {
        return displayWidth
    }
    
    private var displayAreaHeight: CGFloat {
        return displayHeight
    }
    
    private var displayAreaSize: CGFloat {
        return displayWidth // 使用宽度作为基准
    }

    var body: some View {
        ZStack {
            // 设置背景色与ChooseView一致
            Color("#0C0F14")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 添加白色背景，紧贴导航条
                ZStack {
                    // 背景，尺寸371*455，颜色可变
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
                        .frame(width: 371, height: 44)
                        .offset(y: 455/2 + 85) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上85点
                        .zIndex(1) // 确保按钮在最上层
                        .allowsHitTesting(true) // 确保按钮可以接收点击事件
                    }
                    
                    // 在白色背景上层添加图片显示区域，距离白色背景边缘16点
                    ZStack {
                        Rectangle()
                            .fill(Color.white) // 暂用蓝色填充
                            .frame(width: 371, height: 355)
                        
                        // 显示选择的图片
                        if let image = selectedImage {
                            
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill() // 使用fill而不是fit，确保完全填充
                                    .frame(width: displayAreaWidth, height: displayAreaHeight)
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
                                    .clipped() // 隐藏超出显示区域的部分
                                    .allowsHitTesting(true) // 始终允许图片的手势识别
                                    .onAppear {
                                        // 初始化缓存的图片边界
                                        updateCachedImageBounds(for: image)
                                    }
                                    .onChange(of: currentScale) { oldValue, newValue in
                                        // 缩放变化时更新缓存
                                        updateCachedImageBounds(for: image)
                                    }
                                
                                // 添加日期显示在右上角
                                if showDate {
                                    Text(getImageDate(image) ?? "未知日期")
                                        .font(.custom("PixelMplus12-Regular", size: 18))
                                        .fontWeight(.semibold)
                                        .foregroundColor(dateTextColor)
                                        .padding(.trailing, 12)
                                        .padding(.top, 12)
                                }
                            }
                        } else {
                            Text("未选择图片")
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -50) // 向上移动50点，与白色背景顶部对齐
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(formatTextForTwoLines(memoryText).enumerated()), id: \.offset) { index, line in
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
                    .padding(.leading, 16) // 向右移动16点
                    .frame(width: 371, alignment: .leading) // 与显示区宽度一致
                    
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
                    .offset(y: 455/2 + 24 + 180) // 滑动选择按钮下方44点的位置
                    
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
                                        .frame(width: 20, height: 20)
                                    
                                    Text("日期")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text(isUsingCustomDate() ? formatDate(customDate) : (getImageDate(selectedImage) ?? "未知日期"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(Color("#1C1E22"))
                                .cornerRadius(8)
                            }
                            
                            // 地点选项
                            Button(action: {
                                isSettingsPresented = true
                            }) {
                                HStack {
                                    Image("map_b")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                    
                                    Text("地点")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text(getLocationText())
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 44)
                                .background(Color("#1C1E22"))
                                .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                        .frame(width: 343) // 设置固定宽度
                        .offset(y: 455/2 + 85) // 白色背景下方85点的位置
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                        .animation(.easeInOut(duration: 0.3), value: selectedColorOption)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
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
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                customDate: $customDate,
                customLocation: $customLocation,
                showDate: $showDate,
                showLocation: $showLocation
            )
        }
        .sheet(isPresented: $isRememberViewPresented) {
            RememberView(memoryText: $memoryText)
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text(saveAlertTitle),
                message: Text(saveAlertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .onAppear {
            calculateSizes()
        }
    }
    
    // 计算适当的尺寸
    private func calculateSizes() {
        guard selectedImage != nil else { return }
        
        // 设置显示区域尺寸（固定为371*355）
        displayWidth = 371
        displayHeight = 355
        
        // 设置边框尺寸
        frameWidth = displayWidth + 32 // 两侧各留16点边距
        frameHeight = displayHeight + 200 // 顶部和底部留出足够空间给文字
    }
}

// MARK: - 扩展：保存图片到相册
extension FramefiveView {
    private func saveImageToPhotoAlbum() {
        // 检查相册权限
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            proceedWithSavingImage()
        case .denied, .restricted:
            saveAlertTitle = "权限被拒绝"
            saveAlertMessage = "请在设置中允许访问相册权限"
            showSaveAlert = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.proceedWithSavingImage()
                    } else {
                        self.saveAlertTitle = "权限被拒绝"
                        self.saveAlertMessage = "需要相册权限才能保存图片"
                        self.showSaveAlert = true
                    }
                }
            }
        case .limited:
            proceedWithSavingImage()
        @unknown default:
            saveAlertTitle = "未知错误"
            saveAlertMessage = "无法获取相册权限状态"
            showSaveAlert = true
        }
    }
    
    private func proceedWithSavingImage() {
        guard let selectedImage = selectedImage else {
            saveAlertTitle = "保存失败"
            saveAlertMessage = "没有选择图片"
            showSaveAlert = true
            return
        }
        
        #if os(iOS)
        // iOS 实现
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 371, height: 455))
        let finalImage = renderer.image { context in
            // 绘制背景色
            UIColor(frameColor).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 371, height: 455))
            
            // 计算图片在显示区域内的实际绘制位置和尺寸
            let displayRect = CGRect(x: 0, y: 0, width: 371, height: 355)
            
            // 计算缩放后的图片尺寸
            let scaledImageSize = CGSize(
                width: selectedImage.size.width * currentScale,
                height: selectedImage.size.height * currentScale
            )
            
            // 计算图片的绘制位置（考虑用户的拖拽偏移）
            let imageRect = CGRect(
                x: displayRect.midX - scaledImageSize.width/2 + lastValidPosition.width,
                y: displayRect.midY - scaledImageSize.height/2 + lastValidPosition.height,
                width: scaledImageSize.width,
                height: scaledImageSize.height
            )
            
            // 设置裁剪区域为显示区域
            context.cgContext.saveGState()
            context.cgContext.clip(to: displayRect)
            
            // 绘制图片
            selectedImage.draw(in: imageRect)
            
            context.cgContext.restoreGState()
            
            // 绘制日期（如果显示）
            if showDate {
                let dateText = getImageDate(selectedImage) ?? "未知日期"
                let dateAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "PixelMplus12-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor(dateTextColor)
                ]
                
                let dateSize = dateText.size(withAttributes: dateAttributes)
                let dateRect = CGRect(
                    x: displayRect.maxX - dateSize.width - 12,
                    y: displayRect.minY + 12,
                    width: dateSize.width,
                    height: dateSize.height
                )
                
                dateText.draw(in: dateRect, withAttributes: dateAttributes)
            }
            
            // 绘制文字信息
            let textY: CGFloat = 382 // 图片下方的文字位置 (355)
            let textX: CGFloat = 16 // 向右移动16点，与设置部分一致
            let textWidth: CGFloat = 355 // 相应减少宽度
            
            // 绘制标题文字（两行显示）
            let titleLines = formatTextForTwoLines(memoryText)
            var currentY = textY
            
            for line in titleLines {
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                    .foregroundColor: UIColor(titleTextColor)
                ]
                
                let titleSize = line.size(withAttributes: titleAttributes)
                let titleRect = CGRect(
                    x: textX,
                    y: currentY,
                    width: textWidth,
                    height: titleSize.height
                )
                
                line.draw(in: titleRect, withAttributes: titleAttributes)
                currentY += titleSize.height + 2 // 行间距2点
            }
            
            // 绘制地点信息（如果显示）
            if showLocation {
                currentY += 6 // 与标题的间距，对应设置部分VStack的spacing: 6
                
                // 绘制地点图标
                if let mapIcon = UIImage(named: "map_s") {
                    let iconRect = CGRect(x: textX, y: currentY, width: 14, height: 14)
                    
                    // 应用图标颜色
                    let iconWithColor = mapIcon.withTintColor(UIColor(iconColor), renderingMode: .alwaysOriginal)
                    iconWithColor.draw(in: iconRect)
                }
                
                // 绘制地点文字
                let locationText = getLocationText()
                let locationAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor(locationTextColor)
                ]
                
                let locationSize = locationText.size(withAttributes: locationAttributes)
                let locationRect = CGRect(
                    x: textX + 16, // 图标宽度14 + 间距2
                    y: currentY,
                    width: textWidth - 16,
                    height: locationSize.height
                )
                
                locationText.draw(in: locationRect, withAttributes: locationAttributes)
            }
        }
        
        // 保存到相册
         UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
         
         // 显示保存成功提示
         showSaveSuccess()
        
        #elseif os(macOS)
        // macOS 实现
        let imageSize = NSSize(width: 371, height: 455)
        let finalImage = NSImage(size: imageSize)
        
        finalImage.lockFocus()
        
        // 绘制背景色
        NSColor(frameColor).setFill()
        NSRect(x: 0, y: 0, width: 371, height: 455).fill()
        
        // 计算图片在显示区域内的实际绘制位置和尺寸
        let displayRect = NSRect(x: 0, y: 50, width: 371, height: 355)
        
        // 计算缩放后的图片尺寸
        let scaledImageSize = NSSize(
            width: selectedImage.size.width * currentScale,
            height: selectedImage.size.height * currentScale
        )
        
        // 计算图片的绘制位置（考虑用户的拖拽偏移）
        let imageRect = NSRect(
            x: displayRect.midX - scaledImageSize.width/2 + lastValidPosition.width,
            y: displayRect.midY - scaledImageSize.height/2 + lastValidPosition.height,
            width: scaledImageSize.width,
            height: scaledImageSize.height
        )
        
        // 设置裁剪区域为显示区域
        NSGraphicsContext.current?.saveGraphicsState()
        displayRect.clip()
        
        // 绘制图片
        if let nsImage = NSImage(data: selectedImage.pngData() ?? Data()) {
            nsImage.draw(in: imageRect)
        }
        
        NSGraphicsContext.current?.restoreGraphicsState()
        
        // 绘制日期（如果显示）
        if showDate {
            let dateText = getImageDate(selectedImage) ?? "未知日期"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "PixelMplus12-Regular", size: 18) ?? NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: NSColor(dateTextColor)
            ]
            
            let dateSize = dateText.size(withAttributes: dateAttributes)
            let dateRect = NSRect(
                x: displayRect.maxX - dateSize.width - 12,
                y: displayRect.minY + 12,
                width: dateSize.width,
                height: dateSize.height
            )
            
            dateText.draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        // 绘制文字信息
        let textY: CGFloat = 382 // 图片下方的文字位置 (50 + 355)
        let textX: CGFloat = 16 // 向右移动16点，与设置部分一致
        let textWidth: CGFloat = 355 // 相应减少宽度
        
        // 绘制标题文字（两行显示）
        let titleLines = formatTextForTwoLines(memoryText)
        var currentY = textY
        
        for line in titleLines {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: NSColor(titleTextColor)
            ]
            
            let titleSize = line.size(withAttributes: titleAttributes)
            let titleRect = NSRect(
                x: textX,
                y: currentY,
                width: textWidth,
                height: titleSize.height
            )
            
            line.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += titleSize.height + 2 // 行间距2点
        }
        
        // 绘制地点信息（如果显示）
        if showLocation {
            currentY += 6 // 与标题的间距，对应设置部分VStack的spacing: 6
            
            // 绘制地点图标
            if let mapIcon = NSImage(named: "map_s") {
                let iconRect = NSRect(x: textX, y: currentY, width: 14, height: 14)
                mapIcon.draw(in: iconRect)
            }
            
            // 绘制地点文字
            let locationText = getLocationText()
            let locationAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor(locationTextColor)
            ]
            
            let locationSize = locationText.size(withAttributes: locationAttributes)
            let locationRect = NSRect(
                x: textX + 16, // 图标宽度14 + 间距2
                y: currentY,
                width: textWidth - 16,
                height: locationSize.height
            )
            
            locationText.draw(in: locationRect, withAttributes: locationAttributes)
        }
        
        finalImage.unlockFocus()
        
        // macOS 保存逻辑（这里需要根据实际需求实现）
        saveAlertTitle = "导出成功"
        saveAlertMessage = "图片已生成"
        showSaveAlert = true
        #endif
    }
    
    // 由于struct不支持@objc，直接在保存后显示成功提示
    private func showSaveSuccess() {
        saveAlertTitle = "保存成功"
        saveAlertMessage = "图片已保存到相册"
        showSaveAlert = true
    }
    
    // 限制图片偏移量在显示区域内的优化版本
    private func limitOffsetToDisplayAreaOptimized(_ offset: CGSize, scale: CGFloat, image: UIImage) -> CGSize {
        // 使用缓存的边界信息，避免重复计算
        if cachedImageBounds == .zero {
            updateCachedImageBounds(for: image)
        }
        
        // 应用用户的缩放到缓存的尺寸
        let scaledWidth = cachedImageBounds.width * scale
        let scaledHeight = cachedImageBounds.height * scale
        
        // 计算可移动的范围
        let maxOffsetX = max(0, (scaledWidth - displayAreaSize) / 2)
        let maxOffsetY = max(0, (scaledHeight - displayAreaSize) / 2)
        
        // 限制偏移量，确保图片不会移出显示区域
        let limitedX = min(maxOffsetX, max(-maxOffsetX, offset.width))
        let limitedY = min(maxOffsetY, max(-maxOffsetY, offset.height))
        
        return CGSize(width: limitedX, height: limitedY)
    }
    
    // 更新缓存的图片边界
    private func updateCachedImageBounds(for image: UIImage) {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let displayAreaAspectRatio = displayAreaSize / displayAreaSize
        
        var scaledWidth: CGFloat
        var scaledHeight: CGFloat
        
        if imageAspectRatio > displayAreaAspectRatio {
            // 图片较宽，高度适应显示区域
            scaledHeight = displayAreaSize
            scaledWidth = scaledHeight * imageAspectRatio
        } else {
            // 图片较高，宽度适应显示区域
            scaledWidth = displayAreaSize
            scaledHeight = scaledWidth / imageAspectRatio
        }
        
        cachedImageBounds = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
    }
    
    // 截断文本函数
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        } else {
            let index = text.index(text.startIndex, offsetBy: maxLength - 3)
            return String(text[..<index]) + "..."
        }
    }
    
    // 格式化文本为两行显示的函数
    private func formatTextForTwoLines(_ text: String) -> [String] {
        if text.count <= 20 {
            // 如果文本长度不超过20个字符，只显示一行
            return [text]
        } else if text.count <= 35 {
            // 如果文本长度在20-35个字符之间，分两行显示
            let firstLineEnd = text.index(text.startIndex, offsetBy: 20)
            let firstLine = String(text[..<firstLineEnd])
            let secondLine = String(text[firstLineEnd...])
            return [firstLine, secondLine]
        } else {
            // 如果文本长度超过35个字符，第一行20个字符，第二行最多15个字符，超出部分用"···"代替
            let firstLineEnd = text.index(text.startIndex, offsetBy: 20)
            let firstLine = String(text[..<firstLineEnd])
            
            let remainingText = String(text[firstLineEnd...])
            let secondLine: String
            if remainingText.count <= 15 {
                secondLine = remainingText
            } else {
                let secondLineEnd = remainingText.index(remainingText.startIndex, offsetBy: 12)
                secondLine = String(remainingText[..<secondLineEnd]) + "···"
            }
            
            return [firstLine, secondLine]
        }
    }
    
    // 获取照片的地理位置信息
    private func getPhotoLocation(_ image: UIImage) -> String? {
        // 这里应该实现获取照片地理位置的逻辑
        // 由于需要访问照片的元数据，这里返回一个示例
        return nil
    }
    
    // 获取图片拍摄日期
    private func getImageDate(_ image: UIImage?) -> String? {
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
    
    // 检查是否使用自定义日期
    private func isUsingCustomDate() -> Bool {
        // 这里可以添加逻辑来判断是否使用了自定义日期
        // 目前简单返回false
        return false
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    // 获取地点文字
    private func getLocationText() -> String {
        if !customLocation.isEmpty {
            return customLocation
        } else if let selectedImage = selectedImage, let location = getPhotoLocation(selectedImage) {
            return location
        } else {
            return "未知地点"
        }
    }
}

#Preview {
    FramefiveView(selectedImage: UIImage(named: "frame_five"))
}
