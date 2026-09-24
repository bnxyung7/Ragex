import Foundation

enum ExploitSupportPolicy {
    static let verifiedIOS17Range = "17.0–17.7.2"
    static let verifiedIOS18Range = "18.0–18.7.1"
    static let verifiedIOS26Range = "26.0–26.0.1"

    /// Offsets exist only for these releases. 15, 16, 26.1+ and 27 are not covered.
    static func supportsKernelExploit(major: Int, minor: Int = 0, patch: Int = 0) -> Bool {
        switch major {
        case 17: return minor <= 7
        case 18: return minor <= 7
        case 26: return minor == 0
        default: return false
        }
    }

    static func isSupported(major: Int, minor: Int, patch: Int, build: String) -> Bool {
        supportsKernelExploit(major: major, minor: minor, patch: patch)
    }
}
