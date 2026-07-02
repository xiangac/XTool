//
//  XURLRequest.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import CryptoKit

// 💡 使用效果：
// var request = URLRequest(url: url)
// request.x_addIdempotencyToken() // 这样发出的网络请求在服务端就具备了去重依据
//MARK: 避免重复请求
public extension URLRequest {
    
    /// 1. 为当前请求一键注入幂等性令牌 (Idempotency Key)
    /// 避免网络抖动时，客户端重试导致服务端多次创建重复订单
    mutating func x_addIdempotencyToken() {
        let uuid = UUID().uuidString
        self.setValue(uuid, forHTTPHeaderField: "X-Idempotency-Key")
    }
    
    /// 2. 计算请求体的 MD5，用于响应或请求的完整性校验 (Packet Integrity Protection)
    var x_bodyChecksum: String? {
        guard let body = self.httpBody else { return nil }
        let digest = Insecure.MD5.hash(data: body)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}


