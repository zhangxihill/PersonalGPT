//
//  SettingView.swift
//  PersonalGPT
//
//  Created by Vikill Blacks on 2023/3/5.
//

import SwiftUI
import AlertToast

struct SettingView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var user: User
    let values = stride(from: 0.0, to: 2.0, by: 0.1).map{String(format: "%.1f", $0)}
    let step: Double = 0.1
    let models: [String] = ["gpt-4", "gpt-4-0314", "gpt-4-32k", "gpt-4-32k-0314", "gpt-3.5-turbo", "gpt-3.5-turbo-0301"]
    let model_temp_description = "Not all models are avalible now. Check out which models your API apply to on [openai.com](https://openai.com)"
    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(footer: Text(.init(model_temp_description))) {
                    Picker("Model", selection: $settings.model) {
                        ForEach(Models.allCases) { model in
                            Text(model.rawValue)
                                .tag(model)
                        }
                    }
                }
                Section(footer: Text("What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.")) {
                    Picker("Temperature", selection: $settings.temperature) {
                        ForEach(0...20, id: \.self) {
                            Text(String(Double($0)/10)).tag(Double($0)/10)
                        }
                    }
                }
                Section(header: Text("Roles")) {
                    #if os(iOS)
                    NavigationLink(destination: {
                        systemPrompt_SettingView()
                    }, label: {
                        Text("System")
                    })
                    NavigationLink(destination: {
                        assistantPrompt_SettingView()
                    }, label: {
                        Text("Assistant")
                    })
                    #endif
                    #if os(macOS)
                    systemPrompt_SettingView()
                    assistantPrompt_SettingView()
                    #endif
                }
                Section(header: Text("API Key"), footer: Text("You can paste your own API key here.")) {
                    SecureField("API key", text: $settings.api_key)
                        .onSubmit {
                            settings.isShowSubmitAPIToast = true
                        }
                    Button(action: {
                        settings.api_key = ""
                        settings.isShowResetAPIToast = true
                    }, label: {
                        Text("Reset API key")
                    })
                }
                Section(header: Text("About"), footer: Text("This project has been open sourced on GitHub.")) {
                    Link("View in Github", destination: URL(string: "https://github.com/VIkill33/PersonalGPT")!)
                }
                Section {
                    Button(action: {
                        user.chats = []
                        settings.isShowClearToast = true
                    }, label: {
                        Text("Clear History")
                    })
                }
            }
            #if os(macOS)
            .padding()
            .customFormStyle()
            .frame(minWidth: 300.0, minHeight: 700.0)
            #endif
        }
        .toast(isPresenting: $settings.isShowClearToast) {
            AlertToast(displayMode: .hud, type: .regular, title: "Clear All Chats Successfully")
        }
        .toast(isPresenting: $settings.isShowSubmitAPIToast) {
            AlertToast(displayMode: .hud, type: .regular, title: "API Key Saved Successfully")
        }
        .toast(isPresenting: $settings.isShowResetAPIToast) {
            AlertToast(displayMode: .hud, type: .regular, title: "Reset API Key Successfully")
        }
    }
}

struct customFormStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(macOS 13.0, *) {
                content
                    .formStyle(.grouped)
            } else {
                content
            }
        }
    }
}

extension View {
    func customFormStyle() -> some View {
        modifier(customFormStyleModifier())
    }
}

struct systemPrompt_SettingView: View {
    @EnvironmentObject var settings: Settings
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("System Prompt")
                    Spacer()
                    Toggle("", isOn: $settings.isSystemPrompt)
                }
                if settings.isSystemPrompt {
                    TextEditor(text: $settings.systemPrompt)
                }
            }
        }
    }
}

struct assistantPrompt_SettingView: View {
    @EnvironmentObject var settings: Settings
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Assistant Prompt")
                    Spacer()
                    Toggle("", isOn: $settings.isAssistantPrompt)
                }
                if settings.isAssistantPrompt {
                    TextEditor(text: $settings.assistantPrompt)
                }
            }
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
