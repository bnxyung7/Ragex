import Foundation

enum ExploitSupportPolicy {
    static let verifiedIOS17Range = "17.0–17.7.2"
    static let verifiedIOS18Range = "18.0–18.7.10"
    static let verifiedIOS26Range = "26.0–26.7"

    /// Same gate as the kernel offsets: 17.0 through every 26 release, and stop at 27.
    static func supportsKernelExploit(major: Int, minor: Int = 0, patch: Int = 0) -> Bool {
        switch major {
        case 17, 18: return minor <= 7
        case 26: return true
        default: return false
        }
    }

    static func isSupported(major: Int, minor: Int, patch: Int, build: String) -> Bool {
        supportsKernelExploit(major: major, minor: minor, patch: patch)
    }
}
