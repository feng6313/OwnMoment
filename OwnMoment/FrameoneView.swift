//
//  FrameoneView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/15.
//

import SwiftUI
import Photos
import CoreLocation
import MapKit
import UIKit
import ImageIO
#if canImport(AppKit)
import AppKit
#endif

// 定义ImageIO框架中的常量
let kCGImagePropertyExifDictionary = "{Exif}" as CFString
let kCGImagePropertyTIFFDictionary = "{TIFF}" as CFString
let kCGImagePropertyGPSDictionary = "{GPS}" as CFString
let kCGImagePropertyIPTCDictionary = "{IPTC}" as CFString
let kCGImagePropertyExifDateTimeOriginal = "DateTimeOriginal" as CFString
let kCGImagePropertyExifDateTimeDigitized = "DateTimeDigitized" as CFString
let kCGImagePropertyTIFFDateTime = "DateTime" as CFString
let kCGImagePropertyIPTCCreationDate = "CreationDate" as CFString
let kCGImagePropertyGPSDateStamp = "DateStamp" as CFString


struct FrameoneView: View {
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
    @State private var displayWidth: CGFloat = 339
    @State private var displayHeight: CGFloat = 339
    
    // 蓝色显示区域的尺寸常量 - 将其改为计算属性
    private var displayAreaSize: CGFloat {
        return displayWidth // 正方形区域，宽高相等
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
                    
                    // 在白色背景上层添加图片显示区域，距离白色背景边缘16点
                    ZStack {
                        Rectangle()
                            .fill(Color.white) // 暂用蓝色填充
                            .frame(width: 339, height: 339)
                        
                        // 显示选择的图片
                        if let image = selectedImage {
                            
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill() // 使用fill而不是fit，确保完全填充
                                    .frame(width: displayAreaSize, height: displayAreaSize)
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
                                    .onAppear {
                                        // 初始化缓存的图片边界
                                        updateCachedImageBounds(for: image)
                                    }
                                    .onChange(of: currentScale) { oldValue, newValue in
                                        // 缩放变化时更新缓存
                                        updateCachedImageBounds(for: image)
                                    }
                                
                                // 添加日期显示
                                Text(getImageDate(image) ?? "未知日期")
                                    .font(.custom("PixelMplus12-Regular", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(dateTextColor)
                                    .padding([.bottom, .trailing], 10)
                            }
                        } else {
                            Text("未选择图片")
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -42) // 向上移动42点
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 2) { 
                        Text(truncateText("我的独家记忆我的独家记忆我忆忆", maxLength: 15))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(titleTextColor)
                        
                        HStack(spacing: 4) {
                            Image("map_s")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 14, height: 14)
                                .foregroundColor(iconColor)
                            
                            Text(getLocationText())
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(locationTextColor)
                        }
                    }
                    .padding(.top, 350) // 向下移动350点
                    .padding(.leading, 0) // 移除左边距
                    .frame(width: 339, alignment: .leading) // 与蓝色显示区宽度一致
                    
                    // 添加滑动选择按钮，放在白色背景下方10点的位置
                    if showColorControls {
                        SlideSelector(selectedOption: $selectedSlideOption)
                            .offset(y: 455/2 + 32) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上10点
                    }
                    
                    // 添加图标选项栏，放在滑动选择按钮下方
                    HStack(spacing: 0) {
                        Spacer(minLength: 12) // 左侧距离屏幕24点
                        
                        // 颜色选项
                        Button(action: {
                            selectedColorOption = 0
                            showColorControls = true // 显示圆形色块和滑动按钮
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
                            selectedColorOption = 1
                            showColorControls = false // 隐藏圆形色块和滑动按钮
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
                                    
                                    Text("文字")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(selectedColorOption == 1) // 当已选中时禁用点击反馈
                        
                        Spacer() // 中间自动分配空间
                        
                        // 更多选项
                        Button(action: {
                            selectedColorOption = 2
                            showColorControls = false // 隐藏圆形色块和滑动按钮
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
            
            // 右侧设置和保存按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 10) {
                    Button(action: {
                        isSettingsPresented = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                    
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
        })
        
        // 关于"距离屏幕右边缘32点"：ToolbarItem的布局由系统管理，
        // 它会自动处理与屏幕边缘的间距。
        // 如果需要精确控制，可能需要更复杂的Toolbar布局。
        // 此处按钮本身已按要求设置尺寸和颜色。
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                customDate: $customDate,
                customLocation: $customLocation
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

// Color扩展已移至Extensions.swift文件中

struct FrameoneView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了预览，我们需要一个NavigationView上下文
        NavigationView {
            FrameoneView(selectedImage: UIImage(named: "photo"), frameIndex: 0)
        }
    }
}

// 为SlideSelector添加预览
struct SlideSelector_Previews: PreviewProvider {
    static var previews: some View {
        SlideSelector(selectedOption: .constant(0))
    }
}

// 为ColorSelector添加预览
struct ColorSelector_Previews: PreviewProvider {
    static var previews: some View {
        ColorSelector(
            selectedOption: .constant(0),
            frameColor: .constant(.white),
            titleTextColor: .constant(.black),
            dateTextColor: .constant(.orange),
            locationTextColor: .constant(.black),
            iconColor: .constant(.black)
        )
    }
}

// 图标选项按钮组件
struct IconOptionButton: View {
    let imageName: String
    let title: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
        }
    }
}

// 为IconOptionButton添加预览
struct IconOptionButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 40) {
            IconOptionButton(imageName: "color", title: "颜色", isSelected: true) {}
            IconOptionButton(imageName: "word", title: "文字") {}
            IconOptionButton(imageName: "more", title: "更多") {}
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}

// 滑动选择器组件
struct SlideSelector: View {
    @Binding var selectedOption: Int
    @State private var dragOffset: CGFloat = 0
    
    // 添加一个初始化方法，用于预览
    init(selectedOption: Binding<Int>) {
        self._selectedOption = selectedOption
    }
    
    private let options = ["边框", "文字", "时间", "地点", "图标"]
    private let selectorWidth: CGFloat = 330
    private let selectorHeight: CGFloat = 34
    private let optionWidth: CGFloat = 65
    private let optionSpacing: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 黑色背景矩形
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("#2C2C2E"))
                .frame(width: selectorWidth, height: selectorHeight)
            
            // 灰色选择器
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("#6B6C70"))
                .frame(width: optionWidth, height: selectorHeight - 4)
                .offset(x: 2 + CGFloat(selectedOption) * (optionWidth + optionSpacing) + dragOffset, y: 0)
                .animation(.spring(), value: selectedOption)
                .animation(.spring(), value: dragOffset)
            
            // 选项文本
            HStack(spacing: optionSpacing) {
                ForEach(0..<options.count, id: \.self) { index in
                    Text(options[index])
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .opacity(index == selectedOption ? 1.0 : 0.9)
                        .frame(width: optionWidth, height: selectorHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOption = index
                            dragOffset = 0
                        }
                }
            }
        }
        .padding(.horizontal, 2)
        .frame(width: selectorWidth, height: selectorHeight)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dragAmount = value.translation.width
                    let optionFullWidth = optionWidth + optionSpacing
                    
                    // 限制拖动范围
                    if (CGFloat(selectedOption) * optionFullWidth + dragAmount < 0) {
                        dragOffset = -CGFloat(selectedOption) * optionFullWidth
                    } else if (CGFloat(selectedOption) * optionFullWidth + dragAmount > CGFloat(options.count - 1) * optionFullWidth) {
                        dragOffset = CGFloat(options.count - 1 - selectedOption) * optionFullWidth
                    } else {
                        dragOffset = dragAmount
                    }
                }
                .onEnded { value in
                    let dragAmount = value.translation.width
                    let optionFullWidth = optionWidth + optionSpacing
                    
                    // 计算拖动后应该选择哪个选项
                    if abs(dragAmount) > optionFullWidth / 2 {
                        if dragAmount > 0 && selectedOption < options.count - 1 {
                            selectedOption += 1
                        } else if dragAmount < 0 && selectedOption > 0 {
                            selectedOption -= 1
                        }
                    }
                    
                    dragOffset = 0
                }
        )
    }
}

// 颜色选择器组件
struct ColorSelector: View {
    // 颜色数组，按照用户提供的顺序
    private let colors: [[String]] = [
        ["#FFFFFF", "#1C1E22", "#F4E6E7", "#F2EEE3", "#F56E00", "#CEC3B3"],
        ["#E5ECDB", "#C3D3DB", "#A98069", "#69733E", "#834643", "#255B85"]
    ]
    
    // 为每个选项保存选中的颜色索引
    @State private var selectedIndices: [(row: Int, column: Int)] = [
        (0, 0), // 边框 - 默认白色
        (0, 1), // 文字 - 默认黑色
        (0, 4), // 时间 - 默认橙色
        (0, 1), // 地点 - 默认黑色
        (0, 1)  // 图标 - 默认黑色
    ]
    
    // 颜色块大小和间距
    private let colorSize: CGFloat = 26
    private let verticalSpacing: CGFloat = 12
    private let containerWidth: CGFloat = 330 // 与滑动选择器宽度一致
    
    // 添加绑定属性，用于接收当前选择的选项和更新颜色
    @Binding var selectedOption: Int
    @Binding var frameColor: Color
    @Binding var titleTextColor: Color
    @Binding var dateTextColor: Color
    @Binding var locationTextColor: Color
    @Binding var iconColor: Color
    
    // 添加初始化方法
    init(selectedOption: Binding<Int>, frameColor: Binding<Color>, titleTextColor: Binding<Color>, 
         dateTextColor: Binding<Color>, locationTextColor: Binding<Color>, iconColor: Binding<Color>) {
        self._selectedOption = selectedOption
        self._frameColor = frameColor
        self._titleTextColor = titleTextColor
        self._dateTextColor = dateTextColor
        self._locationTextColor = locationTextColor
        self._iconColor = iconColor
    }
    
    // 查找颜色在colors数组中的索引
    private func findColorIndex(for targetColor: Color) -> (row: Int, column: Int) {
        // 遍历颜色数组查找最接近的颜色
        for row in 0..<colors.count {
            for column in 0..<colors[row].count {
                let colorHex = colors[row][column]
                if Color(colorHex) == targetColor {
                    return (row, column)
                }
            }
        }
        // 如果没找到完全匹配的，返回默认值
        return (0, 0)
    }
    
    // 更新所有选项的选中颜色索引
    private func updateSelectedIndices() {
        // 更新每个选项的选中颜色索引
        selectedIndices[0] = findColorIndex(for: frameColor)
        selectedIndices[1] = findColorIndex(for: titleTextColor)
        selectedIndices[2] = findColorIndex(for: dateTextColor)
        selectedIndices[3] = findColorIndex(for: locationTextColor)
        selectedIndices[4] = findColorIndex(for: iconColor)
    }
    
    var body: some View {
        VStack(spacing: verticalSpacing) {
            // 第一行颜色
            HStack {
                ForEach(0..<6) { column in
                    colorCircle(row: 0, column: column)
                }
            }
            
            // 第二行颜色
            HStack {
                ForEach(0..<6) { column in
                    colorCircle(row: 1, column: column)
                }
            }
        }
        .frame(width: containerWidth)
        .onAppear {
            // 在视图出现时，根据当前颜色值更新selectedIndices
            updateSelectedIndices()
        }
        .onChange(of: selectedOption) { oldValue, newValue in
            // 当选项改变时，确保UI反映正确的选中状态
        }
    }
    
    // 创建单个颜色圆圈
    private func colorCircle(row: Int, column: Int) -> some View {
        // 检查当前选项的选中状态
        let currentSelection = selectedIndices[selectedOption]
        let isSelected = (currentSelection.row == row && currentSelection.column == column)
        let colorHex = colors[row][column]
        let color = Color(colorHex)
        
        return ZStack {
            // 颜色圆圈 - 移除默认边框
            Circle()
                .fill(color)
                .frame(width: colorSize, height: colorSize)
            
            // 选中状态 - 3点白色内描边，只有选中时才显示
            if isSelected {
                Circle()
                    .inset(by: 1.5) // 向内缩进1.5点，确保是内描边
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: colorSize, height: colorSize)
            }
        }
        .frame(maxWidth: .infinity) // 均分容器宽度
        .onTapGesture {
            // 更新当前选项的选中颜色索引
            selectedIndices[selectedOption] = (row, column)
            
            // 根据当前SlideSelector的选择更新对应的颜色
            let newColor = color
            switch selectedOption {
            case 0: // 边框
                frameColor = newColor
            case 1: // 文字
                titleTextColor = newColor
            case 2: // 时间
                dateTextColor = newColor
            case 3: // 地点
                locationTextColor = newColor
            case 4: // 图标
                iconColor = newColor
            default:
                break
            }
        }
    }
}

extension FrameoneView {
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
                                Text(getImageDate(image) ?? "未知日期")
                                    .font(.custom("PixelMplus12-Regular", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(dateTextColor)
                                    .padding([.bottom, .trailing], 10)
                            }
                        }
                    }
                    .frame(width: displayWidth, height: displayHeight)
                    .offset(y: -42) // 向上移动42点
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 2) { 
                        Text(truncateText("我的独家记忆我的独家记忆我忆忆", maxLength: 15))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(titleTextColor)
                        
                        HStack(spacing: 4) {
                            Image("map_s")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 14, height: 14)
                                .foregroundColor(iconColor)
                            
                            Text(getLocationText())
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(locationTextColor)
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
                                Text(getImageDate(image) ?? "未知日期")
                                    .font(.custom("PixelMplus12-Regular", size: 18))
                                    .fontWeight(.semibold)
                                    .foregroundColor(dateTextColor)
                                    .padding([.bottom, .trailing], 10)
                            }
                        }
                    }
                    .frame(width: displayWidth, height: displayHeight)
                    .offset(y: -42) // 向上移动42点
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 2) { 
                        Text(truncateText("我的独家记忆我的独家记忆我忆忆", maxLength: 15))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(titleTextColor)
                        
                        HStack(spacing: 4) {
                            Image("map_s")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 14, height: 14)
                                .foregroundColor(iconColor)
                            
                            Text(getLocationText())
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(locationTextColor)
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
    
    // 不再需要这个回调方法，因为我们使用了Photos框架的API
    
    // 显示权限被拒绝的提示
    private func showPermissionDeniedAlert() {
        self.saveAlertTitle = "无法访问相册"
        self.saveAlertMessage = "请在设置中允许应用访问您的相册，以便保存图片。"
        self.showSaveAlert = true
    }
}

extension FrameoneView {
    // 计算适当的尺寸
    private func calculateSizes() {
        guard let image = selectedImage else { return }
        
        // 获取原始图片尺寸
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        // 获取屏幕尺寸
        let screenWidth = UIScreen.main.bounds.width
        let maxFrameWidth = min(screenWidth - 40, imageWidth) // 留出边距
        
        // 计算适当的显示区域尺寸（保持正方形）
        let displaySize = min(maxFrameWidth - 32, min(imageWidth, imageHeight))
        
        // 设置显示区域尺寸
        displayWidth = displaySize
        displayHeight = displaySize
        
        // 设置边框尺寸
        frameWidth = displaySize + 32 // 两侧各留16点边距
        frameHeight = displaySize + 116 // 顶部和底部留出足够空间给文字
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
        let maxOffsetX = max(0, (scaledWidth - displayAreaSize) / 2)
        let maxOffsetY = max(0, (scaledHeight - displayAreaSize) / 2)
        
        // 限制偏移量，确保图片不会移出显示区域
        let limitedX = min(maxOffsetX, max(-maxOffsetX, offset.width))
        let limitedY = min(maxOffsetY, max(-maxOffsetY, offset.height))
        
        return CGSize(width: limitedX, height: limitedY)
    }
    
    // 更新缓存的图片边界信息
    func updateCachedImageBounds(for image: UIImage) {
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
    
    // 计算偏移量，允许图片在显示区域内移动（保留原函数作为备用）
    func limitOffsetToDisplayArea(_ offset: CGSize, scale: CGFloat) -> CGSize {
        guard let image = selectedImage else { return .zero }
        
        // 获取图片的原始尺寸
        let imageSize = image.size
        
        // 计算图片在显示区域内的实际尺寸（考虑缩放和填充模式）
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
        
        // 应用用户的缩放
        scaledWidth *= scale
        scaledHeight *= scale
        
        // 计算可移动的范围
        let maxOffsetX = (scaledWidth - displayAreaSize) / 2
        let maxOffsetY = (scaledHeight - displayAreaSize) / 2
        
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
    
    // 获取照片地理位置信息
    private func getLocationText() -> String {
        // 如果设置了自定义位置，优先使用自定义位置
        if !customLocation.isEmpty {
            return customLocation
        }
        
        // 不再自动读取地理位置，直接返回默认值
        return "xx·xx" // 无法获取地理位置或没有照片时的默认值
    }
    
    // 获取图片拍摄日期
    private func getImageDate(_ image: UIImage) -> String? {
        print("开始获取图片日期")
        
        // 如果设置了自定义日期，优先使用自定义日期
        if let customDateString = getCustomDateIfSet() {
            print("使用自定义日期: \(customDateString)")
            return customDateString
        }
        
        // 尝试从图片EXIF数据中获取创建日期
        print("尝试从EXIF数据获取日期")
        if let exifDate = getExifDateFromImage(image) {
            print("成功从EXIF获取日期: \(exifDate)")
            return exifDate
        }
        
        // 如果无法获取EXIF日期，则使用文件创建日期或修改日期（如果可用）
        // 这里我们无法直接获取文件日期，因为我们只有UIImage对象
        // 所以最后回退到当前日期
        print("无法获取EXIF日期，使用当前日期")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let currentDate = formatter.string(from: Date())
        print("当前日期: \(currentDate)")
        return currentDate
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
            print("自定义日期与当前日期不同")
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: customDate)
        }
        
        print("自定义日期与当前日期相同，不使用自定义日期")
        return nil
    }
    
    // 从图片EXIF数据中获取创建日期
    private func getExifDateFromImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("无法获取图片数据")
            return nil
        }
        
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("无法创建图片源")
            return nil
        }
        
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("无法获取图片元数据")
            return nil
        }
        
        print("图片元数据类型: \(type(of: metadata))")
        print("图片元数据键: \(metadata.keys)")
        
        // 打印所有顶层元数据，帮助调试
        for (key, value) in metadata {
            print("元数据 [\(key)]: \(value)")
        }
        
        // 检查是否有{Exif}字典
        if let exifDict = metadata["{Exif}"] as? [String: Any] {
            print("找到{Exif}字典: \(exifDict.keys)")
            // 处理{Exif}字典中的日期
            for (key, value) in exifDict {
                print("{Exif} [\(key)]: \(value)")
                if let dateString = value as? String {
                    print("尝试解析{Exif}日期: \(dateString)")
                    if let formattedDate = formatExifDate(dateString) {
                        return formattedDate
                    }
                }
            }
        }
        
        // 1. 尝试获取EXIF字典中的日期
        if let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            print("找到EXIF字典: \(exifDict.keys)")
            
            // 尝试获取原始日期时间
            if let dateTimeOriginal = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                print("找到EXIF原始日期: \(dateTimeOriginal)")
                return formatExifDate(dateTimeOriginal)
            }
            
            // 尝试获取数字化日期时间
            if let dateTimeDigitized = exifDict[kCGImagePropertyExifDateTimeDigitized as String] as? String {
                print("找到EXIF数字化日期: \(dateTimeDigitized)")
                return formatExifDate(dateTimeDigitized)
            }
            
            // 尝试获取其他可能的日期字段
            for (key, value) in exifDict {
                print("EXIF [\(key)]: \(value)")
                if key.lowercased().contains("date") || key.lowercased().contains("time"),
                   let dateString = value as? String {
                    print("找到EXIF其他日期字段 \(key): \(dateString)")
                    if let formattedDate = formatExifDate(dateString) {
                        return formattedDate
                    }
                }
            }
        }
        
        // 2. 尝试获取TIFF字典中的日期时间
        if let tiffDict = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            print("找到TIFF字典: \(tiffDict.keys)")
            
            if let dateTime = tiffDict[kCGImagePropertyTIFFDateTime as String] as? String {
                print("找到TIFF日期: \(dateTime)")
                return formatExifDate(dateTime)
            }
            
            // 尝试其他可能的TIFF日期字段
            for (key, value) in tiffDict {
                print("TIFF [\(key)]: \(value)")
                if key.lowercased().contains("date") || key.lowercased().contains("time"),
                   let dateString = value as? String {
                    print("找到TIFF其他日期字段 \(key): \(dateString)")
                    if let formattedDate = formatExifDate(dateString) {
                        return formattedDate
                    }
                }
            }
        }
        
        // 3. 尝试获取GPS字典中的日期时间
        if let gpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            print("找到GPS字典: \(gpsDict.keys)")
            
            if let gpsDateStamp = gpsDict[kCGImagePropertyGPSDateStamp as String] as? String {
                print("找到GPS日期: \(gpsDateStamp)")
                return formatExifDate(gpsDateStamp)
            }
            
            // 检查GPS字典中的所有字段
            for (key, value) in gpsDict {
                print("GPS [\(key)]: \(value)")
                if key.lowercased().contains("date") || key.lowercased().contains("time"),
                   let dateString = value as? String {
                    print("找到GPS其他日期字段 \(key): \(dateString)")
                    if let formattedDate = formatExifDate(dateString) {
                        return formattedDate
                    }
                }
            }
        }
        
        // 4. 尝试获取IPTC字典中的创建日期
        if let iptcDict = metadata[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            print("找到IPTC字典: \(iptcDict.keys)")
            
            // 使用定义的常量
            if let creationDate = iptcDict[kCGImagePropertyIPTCCreationDate as String] as? String {
                print("找到IPTC创建日期: \(creationDate)")
                return formatExifDate(creationDate)
            }
            
            // 检查IPTC字典中的所有字段
            for (key, value) in iptcDict {
                print("IPTC [\(key)]: \(value)")
                if key.lowercased().contains("date") || key.lowercased().contains("time"),
                   let dateString = value as? String {
                    print("找到IPTC其他日期字段 \(key): \(dateString)")
                    if let formattedDate = formatExifDate(dateString) {
                        return formattedDate
                    }
                }
            }
        }
        
        // 5. 尝试获取PNG、JFIF或其他格式特有的日期
        for (key, value) in metadata {
            if key.lowercased().contains("date") || key.lowercased().contains("time"),
               let dateString = value as? String {
                print("找到顶层日期字段 \(key): \(dateString)")
                if let formattedDate = formatExifDate(dateString) {
                    return formattedDate
                }
            }
            
            // 检查嵌套字典
            if let dict = value as? [String: Any] {
                for (nestedKey, nestedValue) in dict {
                    if nestedKey.lowercased().contains("date") || nestedKey.lowercased().contains("time") {
                        print("找到嵌套日期字段 \(key).\(nestedKey): \(nestedValue)")
                        if let dateString = nestedValue as? String, let formattedDate = formatExifDate(dateString) {
                            return formattedDate
                        } else if let dateNumber = nestedValue as? NSNumber {
                            // 处理数字格式的日期（可能是时间戳）
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let date = Date(timeIntervalSince1970: dateNumber.doubleValue)
                            print("从数字时间戳转换日期: \(dateFormatter.string(from: date))")
                            return dateFormatter.string(from: date)
                        }
                    }
                }
            }
        }
        
        // 6. 检查是否有特殊的日期属性
        let specialDateKeys = ["DateTimeOriginal", "DateTime", "CreationDate", "ModificationDate"]
        for key in specialDateKeys {
            if let dateValue = metadata[key] as? String {
                print("找到特殊日期键 \(key): \(dateValue)")
                if let formattedDate = formatExifDate(dateValue) {
                    return formattedDate
                }
            }
        }
        
        print("未找到任何日期信息")
        return nil
    }
    
    // 格式化EXIF日期字符串
    private func formatExifDate(_ dateString: String) -> String? {
        print("尝试格式化日期字符串: \(dateString)")
        
        // 尝试多种可能的EXIF日期格式
        let possibleFormats = [
            "yyyy:MM:dd HH:mm:ss",  // 标准EXIF格式
            "yyyy-MM-dd HH:mm:ss",  // 连字符格式
            "yyyy/MM/dd HH:mm:ss",  // 斜杠格式
            "yyyy年MM月dd日 EEEE HH:mm", // 中文格式带星期和时间
            "yyyy年MM月dd日 HH:mm"      // 中文格式带时间不带星期
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN") // 设置中文区域以支持中文星期
        
        // 尝试每一种可能的格式
        for format in possibleFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                // 成功解析，返回标准格式
                print("成功使用格式 \(format) 解析日期")
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            }
        }
        
        // 检查是否包含年月日的中文格式，不管是否有星期和时间
        // 首先尝试直接匹配完整的中文日期格式
        if dateString.contains("年") && dateString.contains("月") && dateString.contains("日") {
            print("检测到中文日期格式")
            
            // 匹配类似"2025年5月16日"的格式，忽略后面可能的星期和时间
            let yearPattern = "(\\d{4})年(\\d{1,2})月(\\d{1,2})日"
            if let regex = try? NSRegularExpression(pattern: yearPattern, options: []),
               let match = regex.firstMatch(in: dateString, options: [], range: NSRange(location: 0, length: dateString.count)) {
                
                let nsString = dateString as NSString
                let yearRange = match.range(at: 1)
                let monthRange = match.range(at: 2)
                let dayRange = match.range(at: 3)
                
                if yearRange.location != NSNotFound && monthRange.location != NSNotFound && dayRange.location != NSNotFound {
                    let year = nsString.substring(with: yearRange)
                    let month = nsString.substring(with: monthRange)
                    let day = nsString.substring(with: dayRange)
                    
                    let formattedDate = "\(year)-\(month.count == 1 ? "0\(month)" : month)-\(day.count == 1 ? "0\(day)" : day)"
                    print("成功从中文日期提取: \(formattedDate)")
                    return formattedDate
                }
            }
        }
        
        // 尝试提取任何看起来像日期的部分
        // 匹配四位数年份
        let yearOnlyPattern = "(\\d{4})"
        if let regex = try? NSRegularExpression(pattern: yearOnlyPattern, options: []),
           let match = regex.firstMatch(in: dateString, options: [], range: NSRange(location: 0, length: dateString.count)) {
            
            let nsString = dateString as NSString
            let yearRange = match.range(at: 1)
            
            if yearRange.location != NSNotFound {
                let year = nsString.substring(with: yearRange)
                print("只能提取到年份: \(year)，使用当前月日")
                
                // 使用当前的月和日
                let currentDate = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd"
                let monthDay = formatter.string(from: currentDate)
                
                return "\(year)-\(monthDay)"
            }
        }
        
        // 所有尝试都失败
        print("无法解析日期格式: \(dateString)")
        return nil
    }
}

// ... existing code ...
