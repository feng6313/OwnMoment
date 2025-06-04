//
//  RememberView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/15.
//

import SwiftUI

struct RememberView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var memoryText: String
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var currentPresetIndex = 0
    @State private var autoScrollTimer: Timer? = nil
    @State private var keyboardHeight: CGFloat = 0
    
    // 预设的回忆内容
    let presetMemories = [
        "我的独家记忆",
        "所有美好都值得记录",
        "18岁生日",
        "当你无聊的时候，就看看一照片",
        "年轻真好"
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 背景色
                    Color("#0C0F14")
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // 输入区域
                        ZStack(alignment: .topLeading) {
                            // TextEditor
                            TextEditor(text: $inputText)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                                .focused($isInputFocused)
                            
                            // 移除占位文字
                        }
                        .frame(height: max(200, geometry.size.height - keyboardHeight - 100)) // 动态调整高度
                        
                        Spacer()
                    }
                    
                    // 预设回忆内容区域 - 固定在键盘上方20点
                    VStack {
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(presetMemories, id: \.self) { memory in
                                    Button(action: {
                                        inputText = memory
                                    }) {
                                        Text(memory)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color("#2C2C2E"))
                                            )
                                    }
                                    .id(memory)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 40)
                        .onAppear {
                            startAutoScroll()
                        }
                        .onDisappear {
                            stopAutoScroll()
                        }
                    }
                }
            }
            .navigationBarTitle("输入回忆", displayMode: .inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color("#0C0F14"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("添加") {
                    if inputText.count > 35 {
                        memoryText = String(inputText.prefix(35))
                    } else {
                        memoryText = inputText
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color.blue)
            )
        }
        .onAppear {
            // 使用当前的memoryText值初始化inputText
            inputText = memoryText
            isInputFocused = true
            // 设置光标位置到文本末尾
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let text = inputText
                inputText = ""
                inputText = text
            }
            
            // 监听键盘高度变化
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
        }
        .onDisappear {
            // 移除键盘监听
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    // 启动自动轮播
    private func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentPresetIndex = (currentPresetIndex + 1) % presetMemories.count
                // 这里可以添加滚动到指定位置的逻辑
            }
        }
    }
    
    // 停止自动轮播
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}

struct RememberView_Previews: PreviewProvider {
    static var previews: some View {
        RememberView(memoryText: .constant("我的独家记忆"))
    }
}
