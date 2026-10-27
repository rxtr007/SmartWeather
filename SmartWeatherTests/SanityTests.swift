import Foundation
import Testing

@main
struct TestRunner {
    static func main() async {
        let exitCode: CInt = await Testing.__swiftPMEntryPoint()
        exit(exitCode)
    }
}

@Suite("Sanity Checks")
struct SanityTests {
    @Test("Swift Testing test harness executes successfully")
    func testScaffoldSanity() {
        #expect(true)
    }
}
