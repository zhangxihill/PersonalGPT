//
//  BottomBar.swift
//  PersonalGPT
//
//  Created by Vikill Blacks on 2023/3/13.
//

import SwiftUI
import MarkdownUI
#if os(iOS)
import UIKit
#endif

struct BottomBar: View {
    @Binding var status: ChatView_status
    @Binding var promptText: String
    @FocusState var focusedField: Field?
    @Binding var isLoading: Bool
    @Binding var snapshot_proxy: [GeometryProxy]
    @Binding var scrollOffset: CGFloat
    @StateObject var user: User
    var generateText: (api_type, String) -> Void
    var body: some View {
        switch status {
        case .chat:
            HStack {
                TextField("Enter prompt", text: $promptText)
                    .focused($focusedField, equals: .promptText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !isLoading {
                            generateText(.chat ,promptText)
                        }
                    }
                if isLoading {
                    ProgressView()
                        .padding(.horizontal)
                } else {
                    Button(action: {
                        focusedField = nil
                        generateText(.chat ,promptText)
                    }) {
                        Image(systemName: "paperplane.fill")
                    }
                    .padding()
                }
            }
            .disabled(isLoading)
            .padding()
        case .select:
            HStack(alignment: .center) {
                Button(action: {
                    user.unselectAllChats()
                    withAnimation {
                        status = .chat
                    }
                }, label: {
                    Text("Cancel")
                })
                Spacer()
                #if os(macOS)
                Button(action: {
                    // take snapshot
                    take_snapshot()
                }, label: {
                    Text("\(Image(systemName: "square.and.arrow.up.on.square.fill")) Snapshot")
                })
                #endif
                #if os(iOS)
                //ShareLink(item: snapshot(), preview: SharePreview("chat", image: snapshot()))
                Button(action: {
                    // take snapshot
                    take_snapshot()
                }, label: {
                    Text("\(Image(systemName: "square.and.arrow.up.on.square.fill")) Snapshot")
                })
                #endif
            }
            .padding()
        case .snapshot_preview:
            EmptyView()
        }
    }
}


extension BottomBar {
#if os(macOS)
    func take_snapshot() {
        if #available(macOS 13.0, *) {
            var capture_point = snapshot_proxy[0].frame(in: .global).origin
            // var capture_point = CGPoint.zero
            let capture_size = snapshot_proxy[0].size
            
            let content = ZStack {
                Color.primary.colorInvert().edgesIgnoringSafeArea(.all)
                ChatContentView(promptText: $promptText, status: $status, user: user, generateText: self.generateText, isHideUnselectChats: true).frame(width: capture_size.width)
            }
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2.0
            let capture = renderer.nsImage
            
            if let url = showSavePanel() {
                savePNG(image: capture ?? NSImage(), path: url)
            }
        }
    }
#endif
#if os(iOS)
    func take_snapshot() {
        //var capture_point = snapshot_proxy[0].frame(in: .global).origin
        var capture_point = CGPoint.zero
        var capture_size = snapshot_proxy[0].size
        print(capture_point)
        print(capture_size)
        let capture = ChatContent_Text_View(promptText: $promptText, status: $status, user: user, generateText: self.generateText, isHideUnselectChats: true).takeScreenshot(origin: capture_point, size: capture_size)
        UIImageWriteToSavedPhotosAlbum(capture, nil, nil, nil)
    }
#endif
#if os(iOS)
    func snapshot() -> Image {
        //var capture_point = snapshot_proxy[0].frame(in: .global).origin
        // var capture_point = CGPoint.zero
        print("!!!call snapshot")
        user.print_all_chats()
        let content = ZStack {
            Color.primary.colorInvert().edgesIgnoringSafeArea(.all)
            //ChatContentView(promptText: $promptText, status: $status, user: user, generateText: self.generateText, isHideUnselectChats: true).frame(width: UIScreen.main.bounds.width)
            Markdown("132test")
        }
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2.0
        let image = renderer.uiImage
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
        let capture = Image(uiImage: renderer.uiImage!)
        return capture
    }
#endif
}
