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

extension ChatView {
    func generateText(_ apiType: api_type = .chat) {
        DispatchQueue.main.async {
            isLoading = true
        }
        
        var apiKey: String
        var url: String
        var parameters: [String: Any]
        var headers: HTTPHeaders
        
        switch apiType {
        case .completion:
            apiKey = "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"
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
            
            apiKey = "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"
            url = "https://api.openai.com/v1/chat/completions"
            
            user.messsages.append(["content": promptText, "role": "user"])
            let messsages: [String: Any] = ["content": promptText, "role": "user"]
            
            parameters = [
                "model": "gpt-3.5-turbo",
                "messages": user.messsages,
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
                                promptText_shown = promptText
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
                                    promptText_shown = promptText
                                    promptText = ""
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

