import SwiftUI

struct FunctionSettingsView: View {
    @Binding var selectedColorOption: Int
    @Binding var showColorControls: Bool
    @Binding var selectedSlideOption: Int
    @Binding var frameColor: Color
    @Binding var titleTextColor: Color
    @Binding var dateTextColor: Color
    @Binding var locationTextColor: Color
    @Binding var iconColor: Color
    @Binding var userNameColor: Color?
    @Binding var isSettingsPresented: Bool
    
    @State private var selectedTab: Int = 0 // 底部选项卡状态
    @State private var showMemorySheet: Bool = false // 控制回忆内容sheet的显示
    
    var body: some View {
        VStack(spacing: 0) {
            // 滑动选择器 - 位置在导航条350点处
            // 只在选中"颜色"选项卡时显示
            if selectedTab == 0 {
                UniversalSlideSelector(selectedOption: $selectedSlideOption)
                    .offset(y: 332)
            }
            
            // 颜色控制器 - 紧跟在滑动选择器下方
            // 只在选中"颜色"选项卡且showColorControls为true时显示
            if showColorControls && selectedTab == 0 {
                UniversalColorSelector(
                    selectedOption: $selectedSlideOption,
                    frameColor: $frameColor,
                    titleTextColor: $titleTextColor,
                    dateTextColor: $dateTextColor,
                    locationTextColor: $locationTextColor,
                    iconColor: $iconColor,
                    userNameColor: $userNameColor
                )
                .offset(y: 352) // 滑动选择器下方20点
            }
            
            // 文字选项卡内容 - 在icon上方38点处显示标题
            if selectedTab == 1 {
                Text("+点击添加回忆内容")
                    .font(.system(size: 16))
                    .foregroundColor(Color("#838383"))
                    .offset(y: 394) // icon位置432 - 38 = 394
                    .onTapGesture {
                        showMemorySheet = true
                    }
            }
            
            // 底部选项卡
            FunctionTabSelector(selectedTab: $selectedTab)
                .offset(y: 380) // 固定在导航条下方380点处
        }
        .sheet(isPresented: $showMemorySheet) {
            // 回忆内容sheet - 样式稍后设置
            Text("回忆内容编辑界面")
                .font(.title)
                .padding()
        }
    }
}

// 通用滑动选择器组件
struct UniversalSlideSelector: View {
    @Binding var selectedOption: Int
    @State private var dragOffset: CGFloat = 0
    
    let options = ["边框", "标题", "日期", "地点", "图标"]
    
    private var totalWidth: CGFloat {
        UIScreen.main.bounds.width - 48 // 左右各24点边距
    }
    
    private var optionWidth: CGFloat {
        (totalWidth - 4) / CGFloat(options.count) // 选中按钮宽度，总宽度减去左右各2点边距后平均分配
    }
    
    var body: some View {
        ZStack {
            backgroundView
            indicatorView
            optionsView
        }
        .gesture(dragGesture)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color("#2C2C2E"))
            .frame(width: totalWidth, height: 32)
    }
    
    private var indicatorView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color("#6B6C70"))
            .frame(width: optionWidth, height: 28)
            .offset(x: calculateIndicatorOffset())
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedOption)
    }
    
    private var optionsView: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                optionButton(for: index)
            }
        }
    }
    
    private func calculateIndicatorOffset() -> CGFloat {
        // 计算选中按钮的偏移位置，确保左右边距为2点
        let startX = -totalWidth / 2 + 2 // 从左边距2点开始
        return startX + CGFloat(selectedOption) * optionWidth + optionWidth / 2 + dragOffset
    }
    
    private func optionButton(for index: Int) -> some View {
        Text(options[index])
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(selectedOption == index ? Color.white : Color.gray)
            .frame(width: optionWidth)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedOption = index
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                dragOffset = gesture.translation.width
            }
            .onEnded { gesture in
                let currentPosition = CGFloat(selectedOption) * optionWidth + gesture.translation.width
                let targetIndex = Int(round(currentPosition / optionWidth))
                let newIndex = min(max(0, targetIndex), options.count - 1)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedOption = newIndex
                    dragOffset = 0
                }
            }
    }
}

// 通用颜色选择器组件
struct UniversalColorSelector: View {
    @Binding var selectedOption: Int
    @Binding var frameColor: Color
    @Binding var titleTextColor: Color
    @Binding var dateTextColor: Color
    @Binding var locationTextColor: Color
    @Binding var iconColor: Color
    @Binding var userNameColor: Color?
    
    let colors = [
        Color("#FFFFFF"),
        Color("#1C1E22"),
        Color("#F4E6E7"),
        Color("#F2EEE3"),
        Color("#F56E00"),
        Color("#CEC3B3"),
        Color("#E5ECDB"),
        Color("#C3D3DB"),
        Color("#C3D3DB"),
        Color("#69733E"),
        Color("#834643"),
        Color("#255B85")
    ]
    
    private var totalWidth: CGFloat {
        UIScreen.main.bounds.width - 48 // 左右各24点边距
    }
    
    private var colorButtonWidth: CGFloat {
        totalWidth / 6 // 每行6个色块平均分布
    }
    
    var body: some View {
        VStack(spacing: 12) {
            firstRowColors
            secondRowColors
            
            // 新增的选项卡组件 - 这个调用已经被移到主体中，这里应该删除
            // FunctionTabSelector(selectedTab: $selectedTab)
            //     .padding(.top, 12)
        }
        .frame(width: totalWidth)
    }
    
    private var firstRowColors: some View {
        HStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { index in
                colorButton(for: index)
                    .frame(width: colorButtonWidth)
            }
        }
    }
    
    private var secondRowColors: some View {
        HStack(spacing: 0) {
            ForEach(6..<12, id: \.self) { index in
                colorButton(for: index)
                    .frame(width: colorButtonWidth)
            }
        }
    }
    
    private func colorButton(for index: Int) -> some View {
        let isSelected = isColorSelected(colors[index])
        
        return Circle()
            .fill(colors[index])
            .frame(width: 30, height: 30)
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: isSelected ? 3 : 0)
            )
            .onTapGesture {
                updateColors(for: colors[index])
            }
    }
    
    private func isColorSelected(_ color: Color) -> Bool {
        switch selectedOption {
        case 0: // 边框
            return frameColor == color
        case 1: // 标题
            return titleTextColor == color
        case 2: // 日期
            return dateTextColor == color
        case 3: // 地点
            return locationTextColor == color
        case 4: // 图标
            return iconColor == color
        default:
            return false
        }
    }
    
    private func updateColors(for color: Color) {
        switch selectedOption {
        case 0: // 边框
            frameColor = color
        case 1: // 标题
            titleTextColor = color
        case 2: // 日期
            dateTextColor = color
        case 3: // 地点
            locationTextColor = color
        case 4: // 图标
            iconColor = color
        default:
            break
        }
        
        // 如果支持用户名颜色，也同步更新
        if userNameColor != nil {
            if selectedOption == 1 {
                userNameColor = color
            }
        }
    }
}

// 功能选项卡选择器组件
struct FunctionTabSelector: View {
    @Binding var selectedTab: Int // 选中的选项卡
    
    private var totalWidth: CGFloat {
        354 // 根据Figma设计的宽度
    }
    
    private var tabWidth: CGFloat {
        105 // 每个选项卡的宽度
    }
    
    var body: some View {
        HStack(spacing: 19) { // 124-105=19的间距
            // 颜色选项卡
            tabButton(
                index: 0,
                iconName: "color",
                title: "颜色"
            )
            
            // 文字选项卡
            tabButton(
                index: 1,
                iconName: "word",
                title: "文字"
            )
            
            // 更多选项卡
            tabButton(
                index: 2,
                iconName: "more",
                title: "更多"
            )
        }
        .frame(width: totalWidth, height: 70)
    }
    
    private func tabButton(index: Int, iconName: String, title: String) -> some View {
        VStack(spacing: 7) {
            // 图标区域
            ZStack {
                if index == 0 {
                    // 颜色选项的特殊图标 - 四个小圆点
                    HStack(spacing: 2) {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(Color("#005EFF"))
                                .frame(width: 6, height: 6)
                        }
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color("#FF0000"))
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(Color("#FFC300"))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(width: 20, height: 20)
                } else {
                    // 其他选项使用图片
                    Image(iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 20, height: 20)
            
            // 文字标签
            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
        }
        .frame(width: tabWidth, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color("#1C1E22"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            selectedTab == index ? Color.white : Color("#3E3E3E"),
                            lineWidth: 2
                        )
                )
        )
        .onTapGesture {
            selectedTab = index
        }
    }
}
