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
    private var vmFiles: [String] = []
    private var parsingFilename = ""
    private var outputCode = ""
    private var inputfile: (path: String, name: String) = ("", "")
    private var instruction = ""
    
    init(path: String) {
        
        do {
            vmFiles = try fileManager.contentsOfDirectory(atPath: path).filter { $0.isMatch(pattern: PathPattern.vmFilePath) }
            if vmFiles.isEmpty {
                print("cannot find .vm file.")
            }
        } catch {
            print("please pass directory path.")
            return
        }
        
        guard let pathMatch = path.firstMatch(pattern: PathPattern.directoryPath) else {
            return
        }
        inputfile = (path[pathMatch[0]!], path[pathMatch[2]!])
    }
    
    func parse() {
        
        var lineCount = 0
        outputCode += parseBootstrapCode()
        
        for filename in vmFiles {
            guard let data = fileManager.contents(atPath: inputfile.path + filename),
                  let inputCode = String(data: data, encoding: .ascii) else {
                return
            }
            parsingFilename = filename
            
            for line in inputCode.components(separatedBy: .newlines) {
                instruction = line
                
                let commentOutRegExp = try! NSRegularExpression(pattern: CommandPattern.commentOut)
                instruction = commentOutRegExp.stringByReplacingMatches(in: instruction, range: NSMakeRange(0, instruction.count), withTemplate: "")
                instruction = instruction.trimmingCharacters(in: .whitespaces)
                
                if instruction.isEmpty { continue }
                
                do {
                    let type = try commnadType()
                    var output = ""
                    
                    switch type {
                    case .unaryFunction:
                        output = parseUnaryFunction()
                    case .binaryFunction:
                        output = parseBinaryFunction()
                    case .comparisonFunction:
                        output = parseComparisonFunction(index: lineCount)
                    case .push:
                        output = parsePush()
                    case .pop:
                        output = parsePop()
                    case .label:
                        output = parseLabel()
                    case .goto:
                        output = parseGoto()
                    case .ifGoto:
                        output = parseIfGoto()
                    case .function:
                        output = parseFunction()
                    case .call:
                        output = parseCall()
                    case .callReturn:
                        output = parseCallReturn(index: lineCount)
                    }
                    
                    outputCode += output
                    outputCode += "\n"
                    
                    lineCount += 1
                    
                } catch {
                    print("error!")
                }
            }
        }
    }
    
    func output() {
        let data = outputCode.data(using: .ascii)
        fileManager.createFile(atPath: "\(inputfile.path)\(inputfile.name).asm", contents: data)
    }
}

extension Parser {
    
    func commnadType() throws -> CommandType {
        
        if instruction.isMatch(pattern: CommandPattern.unaryFunction) {
            return .unaryFunction
        } else if instruction.isMatch(pattern: CommandPattern.binaryFunction) {
            return .binaryFunction
        } else if instruction.isMatch(pattern: CommandPattern.comparisonFunction) {
            return .comparisonFunction
        } else if instruction.isMatch(pattern: CommandPattern.push) {
            return .push
        } else if instruction.isMatch(pattern: CommandPattern.pop) {
            return .pop
        } else if instruction.isMatch(pattern: CommandPattern.label) {
            return .label
        } else if instruction.isMatch(pattern: CommandPattern.goto) {
            return .goto
        } else if instruction.isMatch(pattern: CommandPattern.ifGoto) {
            return .ifGoto
        } else if instruction.isMatch(pattern: CommandPattern.function) {
            return .function
        } else if instruction.isMatch(pattern: CommandPattern.call) {
            return .call
        } else if instruction.isMatch(pattern: CommandPattern.callReturn) {
            return .callReturn
        } else {
            throw ParseError.illegalInstruction("不正なコマンドが含まれています")
        }
    }
}

extension Parser {
    
    func parseBootstrapCode() -> String {
        var output = """
            @256
            D=A
            @SP
            M=D

            """
        output += parseCall(inst: "call Sys.init 0")
        output += "\n"
        return output
    }
    
    func parseUnaryFunction() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.unaryFunction)!
        let command = instruction[match[1]!]
        
        let commandType = UnaryFunction(rawValue: command)!
        return commandType.parse()
    }
    
    func parseBinaryFunction() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.binaryFunction)!
        let command = instruction[match[1]!]
        
        let commandType = BinaryFunction(rawValue: command)!
        return commandType.parse()
    }
    
    func parseComparisonFunction(index: Int) -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.comparisonFunction)!
        let command = instruction[match[1]!]
        
        let commandType = ComparisonFunction(name: command, index: index)!
        return commandType.parse()
    }
    
    func parsePush() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.push)!
        let segment = instruction[match[1]!]
        let index = instruction[match[2]!]
        
        let type = Push(rawValue: segment)!
        switch type {
        case .constant:
            return """
            @\(index)
            D=A
            @SP
            A=M
            M=D
            @SP
            M=M+1
            """
        case .local:
            return """
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
        case .argument:
            return """
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
        case .this:
            return """
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
        case .that:
            return """
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
        case .pointer:
            return """
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
        case .temp:
            return """
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
        case .static:
            return """
            @\(parsingFilename).\(index)
            D=M
            @SP
            A=M
            M=D
            @SP
            M=M+1
            """
        }
    }
    
    func parsePop() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.pop)!
        let segment = instruction[match[1]!]
        let index = instruction[match[2]!]
        
        let type = Pop(rawValue: segment)!
        switch type {
        case .local:
            return """
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
        case .argument:
            return """
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
        case .this:
            return """
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
        case .that:
            return """
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
        case .pointer:
            return """
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
        case .temp:
            return """
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
        case .static:
            return """
            @SP
            AM=M-1
            D=M
            @\(parsingFilename).\(index)
            M=D
            """
        }
    }
    
    func parseLabel() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.label)!
        let labelName = instruction[match[1]!]
        return "(\(labelName))"
    }
    
    func parseGoto() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.goto)!
        let labelName = instruction[match[1]!]
        return """
        @\(labelName)
        0;JMP
        """
    }
    
    func parseIfGoto() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.ifGoto)!
        let labelName = instruction[match[1]!]
        return """
        @SP
        AM=M-1
        D=M
        @\(labelName)
        D;JNE
        """
    }
    
    func parseCall(inst: String? = nil) -> String {
        let instruction = inst ?? self.instruction
        let match = instruction.firstMatch(pattern: CommandPattern.call)!
        let functionName = instruction[match[1]!]
        let argc = instruction[match[2]!]
        return """
        @\(functionName)_RA
        D=A
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @LCL
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @ARG
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @THIS
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @THAT
        D=M
        @SP
        A=M
        M=D
        @SP
        M=M+1
        @\(argc)
        D=A
        @5
        D=D+A
        @SP
        D=M-D
        @ARG
        M=D
        @SP
        D=M
        @LCL
        M=D
        @\(functionName)
        0;JMP
        (\(functionName)_RA)
        """
    }
    
    func parseFunction() -> String {
        let match = instruction.firstMatch(pattern: CommandPattern.function)!
        let functionName = instruction[match[1]!]
        let lclc = instruction[match[2]!]
        
        var output = "(\(functionName))"
        for _ in 0..<Int(lclc)! {
            output += "\n"
            output += """
            @0
            D=A
            @SP
            A=M
            M=D
            @SP
            M=M+1
            """
        }
        return output
    }
    
    func parseCallReturn(index: Int) -> String {
        return """
        @LCL
        D=M
        @FRAME\(index)
        M=D
        @5
        D=A
        @FRAME\(index)
        A=M-D
        D=M
        @RET\(index)
        M=D
        @SP
        A=M-1
        D=M
        @ARG
        A=M
        M=D
        @ARG
        D=M+1
        @SP
        M=D
        @FRAME\(index)
        AM=M-1
        D=M
        @THAT
        M=D
        @FRAME\(index)
        AM=M-1
        D=M
        @THIS
        M=D
        @FRAME\(index)
        AM=M-1
        D=M
        @ARG
        M=D
        @FRAME\(index)
        AM=M-1
        D=M
        @LCL
        M=D
        @RET\(index)
        A=M
        0;JMP
        """
    }
}

enum ParseError: Error {
    case illegalInstruction(String)
}
