import Foundation

/// Test helper to verify all key durations work correctly
struct KeyDurationTest {
    
    /// Test all durations and print results
    static func testAllDurations() {
        print("\n" + "="*60)
        print("🔑 KEY DURATION TEST - All Durations")
        print("="*60 + "\n")
        
        let testCases: [(KeyDuration, String)] = [
            (.oneHour, "1 Hour"),
            (.threeHours, "3 Hours"),
            (.oneDay, "1 Day"),
            (.threeDays, "3 Days"),
            (.sevenDays, "7 Days"),
            (.fifteenDays, "15 Days"),
            (.thirtyDays, "30 Days"),
            (.sixtyDays, "60 Days"),
            (.permanent, "Permanent")
        ]
        
        for (duration, name) in testCases {
            testDuration(duration, name: name)
        }
        
        print("\n" + "="*60)
        print("✅ ALL TESTS COMPLETED")
        print("="*60 + "\n")
    }
    
    private static func testDuration(_ duration: KeyDuration, name: String) {
        let key = UserKey(keyString: "JUSTINRAGEX-000-000", duration: duration, userName: "Test User")
        
        let expectedSeconds = duration.timeInterval
        let actualSeconds: TimeInterval?
        
        if let expiresAt = key.expiresAt {
            actualSeconds = expiresAt.timeIntervalSince(key.createdAt)
        } else {
            actualSeconds = nil
        }
        
        let passed: Bool
        if let expected = expectedSeconds, let actual = actualSeconds {
            // Allow 1 second tolerance
            passed = abs(expected - actual) < 1.0
        } else if expectedSeconds == nil && actualSeconds == nil {
            passed = true // Both permanent
        } else {
            passed = false
        }
        
        let status = passed ? "✅ PASS" : "❌ FAIL"
        let expectedStr = expectedSeconds != nil ? "\(Int(expectedSeconds!))s" : "nil (permanent)"
        let actualStr = actualSeconds != nil ? "\(Int(actualSeconds!))s" : "nil (permanent)"
        
        print("\(status) | \(name.padding(toLength: 15, withPad: " ", startingAt: 0)) | Expected: \(expectedStr.padding(toLength: 18, withPad: " ", startingAt: 0)) | Actual: \(actualStr)")
        
        // Additional checks
        if passed {
            // Check time remaining display
            let timeRemaining = key.timeRemaining
            print("         ├─ Time Remaining: \(timeRemaining)")
            
            // Check expiration logic
            let isExpired = key.isExpired
            let isValid = key.isValid
            print("         ├─ Is Expired: \(isExpired) (should be false for new key)")
            print("         └─ Is Valid: \(isValid) (should be true for new key)")
            
            if isExpired {
                print("         ⚠️  WARNING: New key should NOT be expired!")
            }
            if !isValid {
                print("         ⚠️  WARNING: New key should be valid!")
            }
        }
        
        print("")
    }
    
    /// Test expiration in real-time (for 1H key)
    static func testRealTimeExpiration() {
        print("\n" + "="*60)
        print("⏱  REAL-TIME EXPIRATION TEST (1 Hour Key)")
        print("="*60 + "\n")
        
        let key = UserKey(keyString: "JUSTINRAGEX-TEST-001", duration: .oneHour, userName: "Test User")
        
        print("Key created at: \(key.createdAt)")
        print("Key expires at: \(key.expiresAt!)")
        print("Duration: 1 Hour (3600 seconds)")
        print("")
        
        // Simulate time passing
        let intervals = [0, 1800, 3000, 3500, 3600, 3601] // 0s, 30min, 50min, 58min, 1h, 1h+1s
        
        for seconds in intervals {
            // Create a key with adjusted expiration
            var testKey = key
            testKey.expiresAt = key.createdAt.addingTimeInterval(3600) // 1 hour from creation
            
            // Simulate current time
            let simulatedNow = key.createdAt.addingTimeInterval(Double(seconds))
            let timeLeft = testKey.expiresAt!.timeIntervalSince(simulatedNow)
            
            let isExpiredNow = simulatedNow > testKey.expiresAt!
            let status = isExpiredNow ? "❌ EXPIRED" : "✅ ACTIVE"
            
            print("After \(seconds)s (\(formatTime(seconds))): \(status)")
            print("  ├─ Time left: \(formatTime(Int(timeLeft)))")
            print("  └─ Is Expired: \(isExpiredNow)")
            print("")
        }
        
        print("="*60)
        print("✅ EXPIRATION TEST COMPLETED")
        print("="*60 + "\n")
    }
    
    private static func formatTime(_ seconds: Int) -> String {
        if seconds < 0 {
            return "expired \(abs(seconds))s ago"
        }
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m \(secs)s"
        } else if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}
