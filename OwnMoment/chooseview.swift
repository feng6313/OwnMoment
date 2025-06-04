//
//  ChooseView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/14.
//

import SwiftUI
import PhotosUI

struct ChooseView: View {
    // 为每个PhotosPicker使用独立的状态变量
    @State private var selectedItems: [PhotosPickerItem?] = Array(repeating: nil, count: 12)
    
    // 用于存储最终选中的图片和边框索引
    @State private var finalSelectedImage: UIImage? = nil
    @State private var finalSelectedFrameIndex: Int? = nil
    
    // 控制到各个FrameView的导航状态
    @State private var navigateToFrameView = false
    
    // 边框图片名称数组
    private let frameImages = [
        "frame_one", "frame_two", "frame_three", "frame_four", 
        "frame_five", "frame_six", "frame_seven", "frame_eight", 
        "frame_nine", "frame_ten", "frame_eleven", "frame_twelve"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 设置背景色
                Color("#0C0F14")
                    .ignoresSafeArea()

                // 使用ScrollView和LazyVGrid来展示12个icon
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ], spacing: 24) {
                        ForEach(0..<12) { index in
                            PhotosPicker(
                                selection: $selectedItems[index],
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(frameImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 155, height: 190)
                            }
                            .onChange(of: selectedItems[index]) { oldValue, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        finalSelectedImage = uiImage
                                        finalSelectedFrameIndex = index
                                        selectedItems[index] = nil // 立即清空，防止记忆上次选择
                                        navigateToFrameView = true // 直接跳转
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24) // 左右边距
                    .padding(.top, 24) // 导航条下方24点的距离
                }
            }
            .navigationTitle("选择边框")
            .navigationBarTitleDisplayMode(.inline)
            // 设置导航栏标题颜色为白色
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color("#0C0F14"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToFrameView) {
                // 根据选择的边框索引导航到对应的视图
                if let frameIndex = finalSelectedFrameIndex {
                    switch frameIndex {
                    case 0:
                        FrameoneView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 1:
                        FrametwoView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 2:
                        FramethreeView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 3:
                        FramefourView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 4:
                        FramefiveView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 5:
                        FramesixView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 6:
                        FramesevenView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 7:
                        FrameeightView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 8:
                        FramenineView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 9:
                        FrametenView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 10:
                        FrameelevenView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    case 11:
                        FrametwelveView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    default:
                        FrameoneView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
                    }
                } else {
                    FrameoneView(selectedImage: finalSelectedImage, frameIndex: 0)
                }
            }
        }
    }
}

#Preview {
    ChooseView()
}