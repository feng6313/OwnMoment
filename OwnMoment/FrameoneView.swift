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

    var body: some View {
        ZStack {
            // 设置背景色与ChooseView一致
            Color(hex: "#0C0F14")
                .ignoresSafeArea()

            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding() // 给图片一些边距
                } else {
                    Text("未选择图片")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer() // 其他内容可以后续添加
            }
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

// Color extension (建议将其移动到单独的工具类文件中，以便全局共享)
// extension Color {
//     init(hex: String) {
//         let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//         var int: UInt64 = 0
//         Scanner(string: hex).scanHexInt64(&int)
//         let a, r, g, b: UInt64
//         switch hex.count {
//         case 3: // RGB (12-bit)
//             (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//         case 6: // RGB (24-bit)
//             (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//         case 8: // ARGB (32-bit)
//             (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//         default:
//             (a, r, g, b) = (1, 1, 1, 0) // Default to black with alpha 0
//         }
//         self.init(
//             .sRGB,
//             red: Double(r) / 255,
//             green: Double(g) / 255,
//             blue:  Double(b) / 255,
//             opacity: Double(a) / 255
//         )
//     }
// }

struct FrameoneView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了预览，我们需要一个NavigationView上下文
        NavigationView {
            FrameoneView(selectedImage: UIImage(systemName: "photo"), frameIndex: 0)
        }
    }
}
