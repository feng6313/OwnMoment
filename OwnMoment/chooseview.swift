//
//  ChooseView.swift
//  OwnMoment
//
//  Created by feng on 2025/5/14.
//

import SwiftUI
import PhotosUI

struct ChooseView: View {
    @State private var selectedItems: [PhotosPickerItem?] = Array(repeating: nil, count: 12)
    @State private var finalSelectedImage: UIImage? = nil
    @State private var finalSelectedFrameIndex: Int? = nil
    @State private var navigateToFrameView = false
    
    private let frameImages = [
        "frame_one", "frame_two", "frame_three", "frame_four", 
        "frame_five", "frame_six", "frame_seven", "frame_eight", 
        "frame_nine", "frame_ten", "frame_eleven", "frame_twelve"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.047, green: 0.059, blue: 0.078)
                    .ignoresSafeArea()

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
                            .onChange(of: selectedItems[index]) { _, newItem in
                                processImageSelection(newItem, index)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("选择边框")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color(red: 0.047, green: 0.059, blue: 0.078), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToFrameView) {
                destinationView
            }
        }
    }
    
    private func processImageSelection(_ newItem: PhotosPickerItem?, _ index: Int) {
        guard let item = newItem else { return }
        
        Task {
            do {
                let data = try await item.loadTransferable(type: Data.self)
                guard let data = data else { return }
                guard let uiImage = UIImage(data: data) else { return }
                
                await MainActor.run {
                    self.finalSelectedImage = uiImage
                    self.finalSelectedFrameIndex = index
                    self.selectedItems[index] = nil
                    self.navigateToFrameView = true
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let frameIndex = finalSelectedFrameIndex {
            switch frameIndex {
            case 0: 
                FrameoneView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
            case 1: 
                FrametwoView(selectedImage: finalSelectedImage, frameIndex: frameIndex)
            case 2:
                FramethreeView()
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

#Preview {
    ChooseView()
}