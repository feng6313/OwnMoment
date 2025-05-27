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
                        Text(truncateText("我的独家记忆我的独家记忆我忆忆", maxLength: 15))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#1C1E22"))
                        
                        HStack(spacing: 4) {
                            Image("map_s")
                                .resizable()
                                .frame(width: 14, height: 14)
                            
                            Text(getLocationText())
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#1C1E22"))
                        }
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
            // 首先尝试从PHAsset中获取位置信息（如果有）
            if let location = getLocationFromPHAsset() {
                return location
            }
            
            // 如果无法从PHAsset获取，则尝试从图片EXIF数据中获取
            if let location = getLocationFromImage(image) {
                return location
            }
            
            return "xx·xx" // 无法获取地理位置时的默认值
        }
        
        return "xx·xx" // 没有照片时的默认值
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
        
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let exifDict = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let gpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            print("无法获取图片元数据或GPS信息")
            return nil
        }
        
        // 提取经纬度信息
        guard let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String,
              let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double else {
            print("无法获取完整的经纬度信息")
            return nil
        }
        
        // 根据参考方向调整经纬度值
        let finalLatitude = latitudeRef == "N" ? latitude : -latitude
        let finalLongitude = longitudeRef == "E" ? longitude : -longitude
        
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
            
            // 构建地理位置字符串
            if let country = placemark.country, let locality = placemark.locality {
                locationString = "\(country)·\(locality)"
            } else if let country = placemark.country {
                locationString = "\(country)"
            } else if let locality = placemark.locality {
                locationString = "\(locality)"
            }
        }
        
        // 等待反地理编码完成，最多等待5秒
        _ = semaphore.wait(timeout: .now() + 5)
        
        return locationString ?? "xx·xx"
    }
}
