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
    @State private var selectedItemFrameOne: PhotosPickerItem? = nil
    @State private var selectedItemFrameTwo: PhotosPickerItem? = nil
    @State private var selectedItemFrameThree: PhotosPickerItem? = nil
    
    // 用于存储最终选中的图片和边框索引
    @State private var finalSelectedImage: UIImage? = nil
    @State private var finalSelectedFrameIndex: Int? = nil
    
    // 控制到FrameoneView的导航状态
    @State private var navigateToFrameOneView = false
    
    // 移除旧的 @State private var selectedItem: PhotosPickerItem? = nil
    // 移除旧的 @State private var selectedImage: UIImage? = nil
    // 移除旧的 @State private var selectedFrameIndex: Int? = nil
    // 移除旧的 @State private var showingPhotoPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 设置背景色
                Color(hex: "#0C0F14")
                    .ignoresSafeArea()

                // 垂直排列的三个图标
                VStack {
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedItemFrameOne, // 绑定到独立的state
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image("frame_one")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 176, height: 130)
                    }
                    .onChange(of: selectedItemFrameOne) { oldValue, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                finalSelectedImage = uiImage
                                finalSelectedFrameIndex = 0
                                selectedItemFrameOne = nil // 立即清空，防止记忆上次选择
                                navigateToFrameOneView = true // 直接跳转
                            }
                        }
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedItemFrameTwo, // 绑定到独立的state
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image("frame_two")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 176, height: 130)
                    }
                    .onChange(of: selectedItemFrameTwo) { oldValue, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                finalSelectedImage = uiImage
                                finalSelectedFrameIndex = 1
                                selectedItemFrameTwo = nil // 立即清空
                                // 如需跳转到其他页面可在此处理
                            }
                        }
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedItemFrameThree, // 绑定到独立的state
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image("frame_three")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 176, height: 130)
                    }
                    .onChange(of: selectedItemFrameThree) { oldValue, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                finalSelectedImage = uiImage
                                finalSelectedFrameIndex = 2
                                selectedItemFrameThree = nil // 立即清空
                                // 如需跳转到其他页面可在此处理
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("选择边框")
            .navigationBarTitleDisplayMode(.inline)
            // 设置导航栏标题颜色为白色
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(hex: "#0C0F14"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToFrameOneView) {
                FrameoneView(selectedImage: finalSelectedImage, frameIndex: finalSelectedFrameIndex)
            }
        }
    }
}

// Color扩展已移至Extensions.swift文件中

#Preview {
    ChooseView()
}