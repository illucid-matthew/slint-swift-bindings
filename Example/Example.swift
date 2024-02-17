//
//  Example.swift
//  Slint
//
//  Created by Matthew Taylor on 2/17/24.
//

import SlintUI

@SlintActor
func test() {
    print("😎 I was invoked from a unstructured task, after the event loop started!")
}

@main
struct ExampleApp: SlintApp {
    static func start() {
        print("⏰ Setting up a timer to fire in three seconds…")
        
        let timer = SlintTimer()
        timer.willRun(after: 3000) {
            print("⏰ Timer fired!")
        }

        Task {
            try! await Task.sleep(nanoseconds: 5_000_000_000)
            test()
        }
    }
}