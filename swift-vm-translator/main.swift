//
//  main.swift
//  swift-vm-translator
//
//  Created by KokiHirokawa on 2019/03/22.
//  Copyright © 2019 KokiHirokawa. All rights reserved.
//

import Foundation

func run() {
    
    guard CommandLine.argc == 2 else {
        print("usage: vmt [filename]")
        return
    }
    
    let args = CommandLine.arguments
    let filepath = args[1]
    let parser = Parser(path: filepath)
    parser.parse()
    parser.output()
}

run()

