//
//  XURLRequest.swift
//  XTool
//
//  Created by xac on 2026/7/2.
//

import Foundation
import CryptoKit

// MARK: - 避免重复请求
public extension URLRequest {
    
    /// 为当前请求注入幂等性令牌（Idempotency Key）
    /// - Note: 写入请求头 `X-Idempotency-Key`，用于避免网络抖动重试导致服务端重复创建
    mutating func x_addIdempotencyToken() {
        let uuid = UUID().uuidString
        self.setValue(uuid, forHTTPHeaderField: "X-Idempotency-Key")
    }
    
    /// 计算请求体的 MD5 校验和，用于请求/响应完整性校验
    var x_bodyChecksum: String? {
        guard let body = self.httpBody else { return nil }
        return XDigestHex.string(from: Insecure.MD5.hash(data: body))
    }
}
