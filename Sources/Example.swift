
import SlintFFI

@MainActor
func test() {
    print("Hello from Swift!")
    SlintFFI.test()
    
    let timer = Timer()
    timer.run(after: 1500) {
       print("After a timer")
    }
}

@main
enum ExampleApp {
    public static func main() throws {
        test()
    }
}