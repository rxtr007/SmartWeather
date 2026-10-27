import Foundation

var testPasses = 0
var testFailures = 0

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if actual == expected {
        testPasses += 1
        print("  ✓ PASS: \(message.isEmpty ? "\(actual) == \(expected)" : message)")
    } else {
        testFailures += 1
        print("  ✗ FAIL [\(file):\(line)]: expected \(expected), got \(actual). \(message)")
    }
}

func assertTrue(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        testPasses += 1
        print("  ✓ PASS: \(message)")
    } else {
        testFailures += 1
        print("  ✗ FAIL [\(file):\(line)]: condition was false. \(message)")
    }
}

@main
struct TestRunner {
    static func main() {
        print("=== Running SmartWeather Test Suite ===")
        
        // Baseline Sanity Test
        testScaffoldSanity()
        
        // Domain Model Tests
        DomainModelTests.run()
        
        // Skiing Scorer Tests
        SkiingScorerTests.run()
        
        // Surfing Scorer Tests
        SurfingScorerTests.run()
        
        // Outdoor Sightseeing Scorer Tests
        OutdoorSightseeingScorerTests.run()
        
        // Indoor Sightseeing Scorer Tests
        IndoorSightseeingScorerTests.run()
        
        // Activity Ranking Engine Tests
        ActivityRankingEngineTests.run()
        
        print("\nResults: \(testPasses) passed, \(testFailures) failed.")
        if testFailures > 0 {
            exit(1)
        }
    }
    
    static func testScaffoldSanity() {
        print("\n[SanityTests]")
        assertTrue(true, "Test harness executes successfully")
        assertEqual(1 + 1, 2, "Basic arithmetic sanity check")
    }
}
