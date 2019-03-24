//
//  Parser.swift
//  swift-vm-translator
//
//  Created by KokiHirokawa on 2019/03/24.
//  Copyright © 2019 KokiHirokawa. All rights reserved.
//

import Foundation

class Parser {
    
    private let fileManager = FileManager.default
    private var inputCode = ""
    private var filename = ""
    private var instruction = ""
    
    init(path: String) {
        guard let data = fileManager.contents(atPath: path), let inputCode = String(data: data, encoding: .ascii) else {
            print("[error] cannot find file.")
            return
        }
        
        self.inputCode = inputCode
        
        guard let pathMatch = path.firstMatch(pattern: RegExpPattern.filePath), let filenameRange = pathMatch[1] else {
            print("please pass *.asm file.")
            return
        }
        filename = path[filenameRange]
    }
    
    func parse() {
        for line in inputCode.components(separatedBy: .newlines) {
            self.instruction = line
            
            let commentOutRegExp = try! NSRegularExpression(pattern: RegExpPattern.commentOut)
            instruction = commentOutRegExp.stringByReplacingMatches(in: instruction, range: NSMakeRange(0, instruction.count), withTemplate: "")
            instruction = instruction.trimmingCharacters(in: .whitespaces)
            
            if instruction.isEmpty { continue }
            
            do {
                let type = try commnadType()
                switch type {
                case .arithmetic:
                    guard let arithmeticMatch = instruction.firstMatch(pattern: RegExpPattern.arithmetic), let commandRange = arithmeticMatch[1] else {
                        return
                    }
                    let command = instruction[commandRange]
                    
                    guard let arithmeticType = Arithmetic(rawValue: command) else { return }
                    let output = arithmeticType.parse()
                    // commandを抽出する正規表現処理
                    // 抽出したコマンドに対応するenumを作成する
                    // parse()をつかってアセンブラを返す
                    break
                case .push:
                    // 一旦来るものは全てconstantとして処理する
                    let index = 10
                    // index部分を抽出する
                    let output = """
                    @\(index)
                    D=A
                    @SP
                    A=M
                    M=D
                    @SP
                    M=M+1
                    """
                    break
                default:
                    break
                }
            } catch {
                print("error!")
            }
        }
    }
    
    func output() {
        
    }
}

extension Parser {
    
    func commnadType() throws -> CommandType {
        
        if instruction.isMatch(pattern: RegExpPattern.arithmetic) {
            return .arithmetic
        } else if instruction.isMatch(pattern: RegExpPattern.push) {
            return .push
        } else if instruction.isMatch(pattern: RegExpPattern.pop) {
            return .pop
        } else {
            throw ParseError.illegalInstruction("不正なコマンドが含まれています")
        }
    }
}

enum ParseError: Error {
    case illegalInstruction(String)
}