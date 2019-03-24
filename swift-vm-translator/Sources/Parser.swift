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
    private var outputCode = ""
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
        
        var lineCount = 0
        
        for line in inputCode.components(separatedBy: .newlines) {
            self.instruction = line
            
            let commentOutRegExp = try! NSRegularExpression(pattern: RegExpPattern.commentOut)
            instruction = commentOutRegExp.stringByReplacingMatches(in: instruction, range: NSMakeRange(0, instruction.count), withTemplate: "")
            instruction = instruction.trimmingCharacters(in: .whitespaces)
            
            if instruction.isEmpty { continue }
            
            do {
                let type = try commnadType()
                var output = ""
                
                switch type {
                case .arithmetic:
                    guard let arithmeticMatch = instruction.firstMatch(pattern: RegExpPattern.arithmetic), let commandRange = arithmeticMatch[1] else {
                        return
                    }
                    let command = instruction[commandRange]
                    
                    guard let arithmeticType = Arithmetic(name: command, index: lineCount) else { return }
                    output = arithmeticType.parse()
                case .push:
                    guard let pushMatch = instruction.firstMatch(pattern: RegExpPattern.push), let segmentRange = pushMatch[1], let indexRange = pushMatch[2] else { return }
                    let segment = instruction[segmentRange]
                    let index = instruction[indexRange]
                    
                    switch segment {
                    case "constant":
                        output = """
                        @\(index)
                        D=A
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "local":
                        output = """
                        @\(index)
                        D=A
                        @LCL
                        A=D+M
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "argument":
                        output = """
                        @\(index)
                        D=A
                        @ARG
                        A=D+M
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "this":
                        output = """
                        @\(index)
                        D=A
                        @THIS
                        A=D+M
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "that":
                        output = """
                        @\(index)
                        D=A
                        @THAT
                        A=D+M
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "pointer":
                        output = """
                        @\(index)
                        D=A
                        @R3
                        A=D+A
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "temp":
                        output = """
                        @\(index)
                        D=A
                        @R5
                        A=D+A
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    case "static":
                        // filenameは最後の部分だけ抽出する
                        output = """
                        @\(filename).\(index)
                        D=M
                        @SP
                        A=M
                        M=D
                        @SP
                        M=M+1
                        """
                    default:
                        break
                    }
                case .pop:
                    guard let popMatch = instruction.firstMatch(pattern: RegExpPattern.pop), let segmentRange = popMatch[1], let indexRange = popMatch[2] else { return }
                    let segment = instruction[segmentRange]
                    let index = instruction[indexRange]
                    
                    switch segment {
                    case "local":
                        output = """
                        @\(index)
                        D=A
                        @LCL
                        D=D+M
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "argument":
                        output = """
                        @\(index)
                        D=A
                        @ARG
                        D=D+M
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "this":
                        output = """
                        @\(index)
                        D=A
                        @THIS
                        D=D+M
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "that":
                        output = """
                        @\(index)
                        D=A
                        @THAT
                        D=D+M
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "pointer":
                        output = """
                        @\(index)
                        D=A
                        @R3
                        D=D+A
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "temp":
                        output = """
                        @\(index)
                        D=A
                        @R5
                        D=D+A
                        @R13
                        M=D
                        @SP
                        AM=M-1
                        D=M
                        @R13
                        A=M
                        M=D
                        """
                    case "static":
                        // filenameは最後の部分だけ抽出する
                        output = """
                        @SP
                        AM=M-1
                        D=M
                        @\(filename).\(index)
                        M=D
                        """
                    default:
                        break
                    }
                default:
                    break
                }
                
                outputCode += output
                outputCode += "\n"
                
                lineCount += 1
                
            } catch {
                print("error!")
            }
        }
    }
    
    func output() {
        let data = outputCode.data(using: .ascii)
        fileManager.createFile(atPath: "\(filename).asm", contents: data)
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
