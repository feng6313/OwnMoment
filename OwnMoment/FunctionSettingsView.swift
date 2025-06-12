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
    
    var body: some View {
        VStack(spacing: 20) {
            // 滑动选择器
            UniversalSlideSelector(selectedOption: $selectedSlideOption)
            
            // 颜色控制器
            if showColorControls {
                UniversalColorSelector(
                    selectedOption: $selectedColorOption,
                    frameColor: $frameColor,
                    titleTextColor: $titleTextColor,
                    dateTextColor: $dateTextColor,
                    locationTextColor: $locationTextColor,
                    iconColor: $iconColor,
                    userNameColor: $userNameColor
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

// 通用滑动选择器组件
struct UniversalSlideSelector: View {
    @Binding var selectedOption: Int
    @State private var dragOffset: CGFloat = 0
    
    let options = ["边框", "标题", "日期", "地点", "图标"]
    let optionWidth: CGFloat = 60
    let totalWidth: CGFloat = 300
    
    var body: some View {
        ZStack {
            backgroundView
            indicatorView
            optionsView
        }
        .gesture(dragGesture)
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color("#2C2C2E"))
            .frame(width: totalWidth, height: 40)
    }
    
    private var indicatorView: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white)
            .frame(width: optionWidth, height: 36)
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
        return CGFloat(selectedOption) * optionWidth - (totalWidth - optionWidth) / 2 + dragOffset
    }
    
    private func optionButton(for index: Int) -> some View {
        Text(options[index])
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(selectedOption == index ? Color.black : Color.white)
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
        Color.white,
        Color.black,
        Color.gray,
        Color("#FF6B35"), // 橙色
        Color("#8B4513"), // 棕色
        Color.green,
        Color.blue,
        Color.purple,
        Color.red,
        Color.yellow,
        Color.pink,
        Color.cyan
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            firstRowColors
            secondRowColors
        }
        .padding(.horizontal, 24)
    }
    
    private var firstRowColors: some View {
        HStack(spacing: 16) {
            ForEach(0..<6, id: \.self) { index in
                colorButton(for: index)
            }
        }
    }
    
    private var secondRowColors: some View {
        HStack(spacing: 16) {
            ForEach(6..<12, id: \.self) { index in
                colorButton(for: index)
            }
        }
    }
    
    private func colorButton(for index: Int) -> some View {
        Circle()
            .fill(colors[index])
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
            )
            .onTapGesture {
                updateColors(for: colors[index])
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