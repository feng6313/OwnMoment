//
//  FrameoneView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/15. // 请修改为实际创建日期
//

import SwiftUI

struct FrameoneView: View {
    @Environment(\.presentationMode) var presentationMode
    var selectedImage: UIImage?
    var frameIndex: Int? // 标识是从哪个相框点击进入的
    
    // 添加状态变量来跟踪缩放和位置
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    @State private var currentPosition: CGSize = .zero
    @State private var previousPosition: CGSize = .zero
    
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
                    // 白色背景，尺寸371*455
                    Rectangle()
                        .fill(Color.white)
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
                        } else {
                            Text("未选择图片")
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -42) // 向上移动42点
                    
                    // 添加图片下方的文字信息
                    VStack(alignment: .leading, spacing: 2) {
                        Text(truncateText("我的独家记忆我的独家记忆我的独家记忆我的", maxLength: 15))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#1C1E22"))
                        
                        Text(getLocationText())
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "#1C1E22"))
                    }
                    .padding(.top, 350) // 向下移动350点
                    .padding(.leading, 0) // 移除左边距
                    .frame(width: 339, alignment: .leading) // 与蓝色显示区宽度一致
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
            // 右侧保存按钮
            ToolbarItem(placement: .navigationBarTrailing) {
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

            // 关于“距离屏幕右边缘32点”：ToolbarItem的布局由系统管理，
            // 它会自动处理与屏幕边缘的间距。
            // 如果需要精确控制，可能需要更复杂的Toolbar布局。
            // 此处按钮本身已按要求设置尺寸和颜色。
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
        // 如果有selectedImage，尝试从其中读取地理位置元数据
        if let image = selectedImage {
            // 实际项目中，应该使用以下方法获取地理位置：
            // 1. 如果是从相册选择的照片，可以使用PHAsset获取位置信息
            // 2. 如果是直接传入的UIImage，可以尝试从其metadata中读取EXIF信息
            // 3. 获取到经纬度后，可以使用CLGeocoder进行反地理编码获取地点名称
            
            // 以下是示例代码，实际项目中需要替换为真实实现
            // 模拟从照片中读取地理位置信息
            if let location = getLocationFromImage(image) {
                return location
            } else {
                return "xx·xx" // 无法获取地理位置时的默认值
            }
        }
        
        return "xx·xx" // 没有照片时的默认值
    }
    
    // 从图片中获取地理位置信息（模拟函数）
    // 实际项目中应该实现真正的地理位置获取逻辑
    private func getLocationFromImage(_ image: UIImage) -> String? {
        // 这里应该实现从图片中提取地理位置信息的逻辑
        // 例如：从图片的EXIF数据中获取GPS信息，然后使用CLGeocoder进行反地理编码
        
        // 实际项目中，应该尝试从图片的EXIF数据中读取GPS信息
        // 如果成功获取到GPS信息，则使用CLGeocoder进行反地理编码获取地点名称
        // 这里为了演示，直接返回模拟的地理位置信息
        
        // 模拟成功获取地理位置
        // 实际项目中应返回真实的地理位置信息
        let locations = ["中国·北京", "中国·上海", "中国·广州", "中国·深圳", "中国·杭州"]
        return locations[Int.random(in: 0..<locations.count)]
    }
}
