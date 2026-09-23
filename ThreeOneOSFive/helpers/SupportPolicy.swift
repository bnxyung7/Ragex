import Foundation

enum ExploitSupportPolicy {
    static let verifiedIOS17Range = "17.0–17.7.x"
    static let verifiedIOS18Range = "18.0–18.7.x"
    static let verifiedIOS26Range = "26.0–26.6.2"

    static func supportsKernelExploit(major: Int, minor: Int, patch: Int) -> Bool {
        return true
    }

    static func isSupported(major: Int, minor: Int, patch: Int, build: String) -> Bool {
        return true
    }
}
