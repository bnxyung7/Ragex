import Foundation

enum ExploitSupportPolicy {
    static let verifiedIOS17Range = "17.0–17.7.x"
    static let verifiedIOS18Range = "18.0–18.7.x"
    static let verifiedIOS26Range = "26.0–26.6.2"

    /// Kernel offsets in this IPA stop before iOS 27. Running the exploit there only wastes time and can crash.
    static func supportsKernelExploit(major: Int, minor: Int = 0, patch: Int = 0) -> Bool {
        major >= 17 && major < 27
    }

    static func isSupported(major: Int, minor: Int, patch: Int, build: String) -> Bool {
        supportsKernelExploit(major: major, minor: minor, patch: patch)
    }
}
