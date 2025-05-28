//
//  FrameoneView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/15. // 请修改为实际创建日期
//

import SwiftUI
import Photos
import CoreLocation
import ImageIO

struct FrameoneView: View {
    @Environment(\.presentationMode) var presentationMode
    var selectedImage: UIImage?
    var frameIndex: Int? // 标识是从哪个相框点击进入的
    
    // 添加状态变量来跟踪缩放和位置
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var currentPosition: CGSize = .zero
    @State private var previousPosition: CGSize = .zero
    
    // 添加设置相关的状态变量
    @State private var isSettingsPresented = false
    @State private var customDate = Date()
    @State private var customLocation = ""
    
    // 添加颜色相关的状态变量
    @State private var frameColor: Color = .white // 边框颜色
    @State private var titleTextColor: Color = Color(hex: "#1C1E22") // 标题文字颜色
    @State private var dateTextColor: Color = Color(hex: "#F56E00") // 时间颜色
    @State private var locationTextColor: Color = Color(hex: "#1C1E22") // 地点文字颜色
    @State private var iconColor: Color = Color(hex: "#1C1E22") // 图标颜色
    @State private var selectedColorOption = 0 // 当前选中的颜色选项（下方矩形框）
    @State private var selectedSlideOption = 0 // 当前选中的滑动选项（上方滑动按钮）
    @State private var showColorControls: Bool = true // 控制圆形色块和滑动按钮的显示
    
    // 蓝色显示区域的尺寸常量
    private let displayAreaSize: CGFloat = 339

    var body: some View {
        ZStack {
            // 设置背景色与ChooseView一致
            Color(hex: "#0C0F14")
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
                            .fill(Color.blue) // 暂用蓝色填充
                            .frame(width: 339, height: 339)
                        
                        // 显示选择的图片
                        if let image = selectedImage {
                            // 获取图片的宽高比 - 注释掉未使用的变量
                            // let imageWidth = image.size.width
                            // let imageHeight = image.size.height
                            // let isWiderThanTall = imageWidth > imageHeight
                            
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill() // 使用fill而不是fit，确保完全填充
                                    .frame(width: displayAreaSize, height: displayAreaSize)
                                    // 应用缩放效果
                                    .scaleEffect(currentScale)
                                    // 应用位置偏移，但限制在显示区域内
                                    .offset(limitOffsetToDisplayArea(currentPosition, scale: currentScale))
                                    // 添加手势识别
                                    .gesture(
                                        // 组合缩放和拖动手势
                                        SimultaneousGesture(
                                            // 缩放手势
                                            MagnificationGesture()
                                                .onChanged { value in
                                                    // 限制缩放范围在1.0到5.0之间
                                                    let newScale = min(max(previousScale * value, 1.0), 5.0)
                                                    currentScale = newScale
                                                }
                                                .onEnded { value in
                                                    // 保存当前缩放值作为下次手势的基准
                                                    previousScale = currentScale
                                                },
                                            // 拖动手势
                                            DragGesture()
                                                .onChanged { value in
                                                    // 计算新的位置
                                                    let newPosition = CGSize(
                                                        width: previousPosition.width + value.translation.width,
                                                        height: previousPosition.height + value.translation.height
                                                    )
                                                    currentPosition = newPosition
                                                }
                                                .onEnded { value in
                                                    // 保存当前位置作为下次手势的基准
                                                    previousPosition = currentPosition
                                                }
                                        )
                                    )
                                    .clipped() // 隐藏超出显示区域的部分
                                
                                // 添加日期显示
                                Text(getImageDate(image) ?? "未知日期")
                                    .font(.custom("Rajdhani", size: 18))
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
                            .offset(y: 455/2 + 24) // 白色背景高度为455，除以2得到从中心到底部的距离，再加上10点
                    }
                    
                    // 添加图标选项栏，放在滑动选择按钮下方
                    HStack(spacing: 0) {
                        Spacer(minLength: 24) // 左侧距离屏幕24点
                        
                        // 颜色选项
                        Button(action: {
                            selectedColorOption = 0
                            showColorControls = true // 显示圆形色块和滑动按钮
                        }) {
                            ZStack {
                                // 圆角矩形框
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#1C1E22"))
                                    .frame(width: 107, height: 70)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedColorOption == 0 ? Color.white : Color(hex: "#3E3E3E"), lineWidth: 2)
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
                                    .fill(Color(hex: "#1C1E22"))
                                    .frame(width: 107, height: 70)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedColorOption == 1 ? Color.white : Color(hex: "#3E3E3E"), lineWidth: 2)
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
                                    .fill(Color(hex: "#1C1E22"))
                                    .frame(width: 107, height: 70)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(selectedColorOption == 2 ? Color.white : Color(hex: "#3E3E3E"), lineWidth: 2)
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
                        
                        Spacer(minLength: 24) // 右侧距离屏幕24点
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
            .padding(.top) // 确保与导航栏有适当间距
        }
        .navigationBarBackButtonHidden(true) // 隐藏默认返回按钮
        .navigationBarTitleDisplayMode(.inline) // 确保标题居中
        .toolbarColorScheme(.dark, for: .navigationBar) // 保持导航栏颜色风格一致
        .toolbarBackground(Color(hex: "#0C0F14"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
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
                    }) {
                        Text("保存")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 30, alignment: .center)
                            .background(Color(hex: "#007AFF"))
                            .cornerRadius(15)
                    }
                }
            }

            // 关于“距离屏幕右边缘32点”：ToolbarItem的布局由系统管理，
            // 它会自动处理与屏幕边缘的间距。
            // 如果需要精确控制，可能需要更复杂的Toolbar布局。
            // 此处按钮本身已按要求设置尺寸和颜色。
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                customDate: $customDate,
                customLocation: $customLocation
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
                .fill(Color(hex: "#2C2C2E"))
                .frame(width: selectorWidth, height: selectorHeight)
            
            // 灰色选择器
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#6B6C70"))
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
            .padding(.horizontal, 2)
        }
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
        ["#E5ECDB", "#C3D3DB", "#C3D3DB", "#69733E", "#834643", "#255B85"]
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
        
        // 初始化selectedIndices，根据传入的颜色值设置初始选中状态
        // 注意：这里我们只能设置默认值，实际的颜色匹配需要在onAppear中完成
    }
    
    // 查找颜色在colors数组中的索引
    private func findColorIndex(for targetColor: Color) -> (row: Int, column: Int) {
        // 遍历颜色数组查找最接近的颜色
        for row in 0..<colors.count {
            for column in 0..<colors[row].count {
                let colorHex = colors[row][column]
                if Color(hex: colorHex) == targetColor {
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
            // 这里不需要额外操作，因为我们在colorCircle中已经处理了
        }
    }
    
    // 创建单个颜色圆圈
    private func colorCircle(row: Int, column: Int) -> some View {
        // 检查当前选项的选中状态
        let currentSelection = selectedIndices[selectedOption]
        let isSelected = (currentSelection.row == row && currentSelection.column == column)
        let colorHex = colors[row][column]
        let color = Color(hex: colorHex)
        
        return ZStack {
            // 颜色圆圈
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
            
            // 根据当前选择的选项更新对应的颜色
            switch selectedOption {
            case 0: // 边框
                frameColor = color
            case 1: // 文字
                titleTextColor = color
            case 2: // 时间
                dateTextColor = color
            case 3: // 地点
                locationTextColor = color
            case 4: // 图标
                iconColor = color
            default:
                break
            }
        }
    }
}

extension FrameoneView {
    // 计算偏移量，允许图片在显示区域内移动
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
    func getLocationText() -> String {
        // 如果设置了自定义位置，优先使用自定义位置
        if !customLocation.isEmpty {
            return customLocation
        }
        
        // 如果有selectedImage，尝试从其中读取地理位置元数据
        if let image = selectedImage {
            // 首先尝试从PHAsset中获取位置信息（如果有）
            if let location = getLocationFromPHAsset() {
                return location
            }
            
            // 如果无法从PHAsset获取，则尝试从图片EXIF数据中获取
            if let location = getLocationFromImage(image) {
                return location
            }
        }
        
        return "xx·xx" // 无法获取地理位置或没有照片时的默认值
    }
    
    // 从PHAsset中获取地理位置信息
    private func getLocationFromPHAsset() -> String? {
        // 注意：这个函数需要在实际项目中实现
        // 需要保存选择照片时对应的PHAsset引用
        // 这里仅提供示例代码框架
        
        // 假设我们有一个存储选中照片对应PHAsset的属性
        // var selectedAsset: PHAsset?
        
        // guard let asset = selectedAsset, asset.location != nil else {
        //     return nil
        // }
        
        // let location = asset.location!
        // let geocoder = CLGeocoder()
        // var locationString: String? = nil
        
        // let semaphore = DispatchSemaphore(value: 0)
        
        // geocoder.reverseGeocodeLocation(location) { placemarks, error in
        //     defer { semaphore.signal() }
        //     
        //     if let error = error {
        //         print("反地理编码错误: \(error.localizedDescription)")
        //         return
        //     }
        //     
        //     guard let placemark = placemarks?.first else {
        //         print("未找到地标信息")
        //         return
        //     }
        //     
        //     if let country = placemark.country, let locality = placemark.locality {
        //         locationString = "\(country)·\(locality)"
        //     } else if let country = placemark.country {
        //         locationString = "\(country)"
        //     } else if let locality = placemark.locality {
        //         locationString = "\(locality)"
        //     }
        // }
        
        // _ = semaphore.wait(timeout: .now() + 5)
        // return locationString
        
        // 由于我们没有实际的PHAsset引用，这里返回nil
        return nil
    }
    
    // 获取图片拍摄日期
    private func getImageDate(_ image: UIImage) -> String? {
        // 使用自定义日期
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd"
        return formatter.string(from: customDate)
    }
    
    // 格式化EXIF日期字符串
    private func formatExifDate(_ dateString: String) -> String? {
        // EXIF日期格式通常为："yyyy:MM:dd HH:mm:ss"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "yyyy:MM:dd"
            return formatter.string(from: date)
        }
        
        return nil
    }
    
    // 从图片中获取地理位置信息
    private func getLocationFromImage(_ image: UIImage) -> String? {
        // 尝试从图片的EXIF数据中获取GPS信息
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
        
        // 检查是否存在GPS字典
        guard let gpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            print("图片中不包含GPS信息")
            return nil
        }
        
        // 提取经纬度信息 - 处理不同格式的GPS数据
        var finalLatitude: Double = 0
        var finalLongitude: Double = 0
        
        // 处理标准格式的GPS数据
        if let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
           let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
           let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String,
           let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
            
            finalLatitude = latitudeRef == "N" ? latitude : -latitude
            finalLongitude = longitudeRef == "E" ? longitude : -longitude
        }
        // 处理某些设备可能使用的数组格式GPS数据
        else if let latitudeArray = gpsDict[kCGImagePropertyGPSLatitude as String] as? [Double],
                let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
                let longitudeArray = gpsDict[kCGImagePropertyGPSLongitude as String] as? [Double],
                let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String,
                !latitudeArray.isEmpty && !longitudeArray.isEmpty {
            
            // 将度分秒格式转换为十进制度
            let latDegrees = latitudeArray[0]
            let latMinutes = latitudeArray.count > 1 ? latitudeArray[1] / 60.0 : 0
            let latSeconds = latitudeArray.count > 2 ? latitudeArray[2] / 3600.0 : 0
            let rawLatitude = latDegrees + latMinutes + latSeconds
            
            let lonDegrees = longitudeArray[0]
            let lonMinutes = longitudeArray.count > 1 ? longitudeArray[1] / 60.0 : 0
            let lonSeconds = longitudeArray.count > 2 ? longitudeArray[2] / 3600.0 : 0
            let rawLongitude = lonDegrees + lonMinutes + lonSeconds
            
            finalLatitude = latitudeRef == "N" ? rawLatitude : -rawLatitude
            finalLongitude = longitudeRef == "E" ? rawLongitude : -rawLongitude
        } else {
            print("无法解析GPS数据格式")
            return nil
        }
        
        // 验证经纬度是否在有效范围内
        if abs(finalLatitude) > 90 || abs(finalLongitude) > 180 {
            print("经纬度值超出有效范围")
            return nil
        }
        
        // 使用CLGeocoder进行反地理编码
        let location = CLLocation(latitude: finalLatitude, longitude: finalLongitude)
        let geocoder = CLGeocoder()
        var locationString: String? = nil
        
        // 创建一个信号量来等待异步操作完成
        let semaphore = DispatchSemaphore(value: 0)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("反地理编码错误: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("未找到地标信息")
                return
            }
            
            // 构建地理位置字符串 - 优先使用城市和区域信息
            if let locality = placemark.locality, let subLocality = placemark.subLocality {
                // 城市和区，例如：北京·朝阳区
                locationString = "\(locality)·\(subLocality)"
            } else if let country = placemark.country, let locality = placemark.locality {
                // 国家和城市，例如：中国·北京
                locationString = "\(country)·\(locality)"
            } else if let administrativeArea = placemark.administrativeArea, let locality = placemark.locality {
                // 省和城市，例如：广东·广州
                locationString = "\(administrativeArea)·\(locality)"
            } else if let locality = placemark.locality {
                // 仅城市，例如：上海
                locationString = locality
            } else if let country = placemark.country {
                // 仅国家，例如：日本
                locationString = country
            } else {
                // 如果没有有意义的地理信息，使用经纬度
                let latString = String(format: "%.4f", finalLatitude)
                let lonString = String(format: "%.4f", finalLongitude)
                locationString = "\(latString),\(lonString)"
            }
        }
        
        // 等待反地理编码完成，最多等待5秒
        _ = semaphore.wait(timeout: .now() + 5)
        
        return locationString
    }
}
