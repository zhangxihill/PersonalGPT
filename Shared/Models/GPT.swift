//
//  GPT.swift
//  PersonalGPT
//
//  Created by Vikill Blacks on 2023/3/3.
//

import SwiftUI
import Alamofire
import SwiftyJSON

enum api_type {
    case completion
    case chat
}

enum Models: String, CaseIterable, Identifiable {
    case gpt4 = "gpt-4"
    case gpt40314 = "gpt-4-0314"
    case gpt432k = "gpt-4-32k"
    case gpt432k0314 = "gpt-4-32k-0314"
    case gpt35turbo = "gpt-3.5-turbo"
    case gpt35turbo0301 = "gpt-3.5-turbo-0301"
    var id: String {self.rawValue}
}

extension ChatView {
    func generateText(_ apiType: api_type = .chat, prompt_text: String) -> Void {
        DispatchQueue.main.async {
            isLoading = true
        }
        
        var apiKey: String
        var url: String
        var parameters: [String: Any]
        var headers: HTTPHeaders
        
        switch apiType {
        case .completion:
            apiKey = settings.api_key
            url = "https://api.openai.com/v1/completions"
            
            parameters = [
                "model": "text-davinci-003",
                "prompt": promptText,
                "max_tokens": 1000
            ]
            
            headers = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(apiKey)"
            ]
        case .chat:
            
            apiKey = settings.api_key
            url = "https://api.openai.com/v1/chat/completions"
            
            if user.chats.isEmpty {
                if settings.isSystemPrompt {
                    user.chats.append(Chat(messsages: ["role": "system", "content": settings.systemPrompt], answers: ""))
                }
                if settings.isAssistantPrompt {
                    user.chats.append(Chat(messsages: ["role": "assistant", "content": settings.assistantPrompt], answers: ""))
                }
            }
            
            user.chats.append(Chat(messsages: ["content": prompt_text, "role": "user"], answers: ""))
            // user.chat.messsages.append(["content": promptText, "role": "user"])
            
            parameters = [
                "model": settings.model.rawValue,
                "messages": user.messageArray(),
                "max_tokens": 1000,
                "user": user.id.uuidString
            ]
            
            headers = [
                "Content-Type": "application/json",
                "Authorization": "Bearer \(apiKey)"
            ]
        }
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
                isLoading = false
                print(response)
                    switch apiType {
                    case .completion:
                        if let value = response.value {
                            let json = JSON(value)
                            let choices = json["choices"].arrayValue
                            let text = choices.map { $0["text"].stringValue }.joined()
                            DispatchQueue.main.async {
                                generatedText = trimStr(text)
                                promptText = ""
                            }
                        }
                    case .chat:
                        if let data = response.data {
                            let json = try! JSON(data: data)
                            if let choices = json["choices"].array,
                               let firstChoice = choices.first,
                               let message = firstChoice["message"]["content"].string {
                                // 处理得到的消息内容
                                DispatchQueue.main.async {
                                    generatedText = trimStr(message)
                                    user.chats[user.chats.count - 1].messsages["content"] = prompt_text
                                    user.chats[user.chats.count - 1].answers = generatedText
                                    user.chats[user.chats.count - 1].date = Date()
                                    print(user.chats.last?.answers)
                                    promptText = ""
                                }
                            } else {
                                var error_message = "Oops, something went wrong!"
                                var error_type = ""
                                if let error = json["error"].dictionary,
                                   let message = error["message"]?.string,
                                   let type = error["type"]?.string {
                                    let components = message.components(separatedBy: ".")
                                    error_message = components.first ?? message
                                    error_type = type
                                    print(message)
                                    print(type)
                                }
                                DispatchQueue.main.async {
                                    toastTitle = error_message
                                    toastSubtitle = error_type
                                    settings.isShowErrorToast = true
                                }
                            }
                        }
                    }
            }
    }
}

func trimStr(_ rawStr: String) -> String {
    var checkStr: [Character] = ["c", "c"]
    var index = 0
    for c in rawStr {
        checkStr.remove(at: 0)
        checkStr.append(c)
        index += 1
        if checkStr[0] == "\n" && checkStr[1] == "\n" {
            break
        }
    }
    if index == rawStr.count {
        return rawStr
    } else {
        return String(rawStr.dropFirst(index))
    }
}

