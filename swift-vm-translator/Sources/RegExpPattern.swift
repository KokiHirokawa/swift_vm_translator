//
//  RegExpPattern.swift
//  swift-vm-translator
//
//  Created by KokiHirokawa on 2019/03/24.
//  Copyright © 2019 KokiHirokawa. All rights reserved.
//

struct RegExpPattern {
    public static let commentOut = "/{2}.*"
    public static let arithmetic = "^(add|sub|neg|eq|gt|lt|and|or|not)$"
    public static let push = "^push[\\s]+([\\w]+)[\\s]+([\\w]+)"
    public static let pop = "^pop[\\s]+([\\w]+)[\\s]+([\\w]+)"
    
    public static let filePath = "(.*)\\.vm$"
    
}

enum CommandType {
    case arithmetic
    case push
    case pop
    case label
    case goto
    case `if`
    case function
    case `return`
    case call
}

enum Arithmetic {
    case add
    case sub
    case neg
    case eq(Int)
    case gt(Int)
    case lt(Int)
    case and
    case or
    case not
    
    init?(name: String, index: Int) {
        switch name {
        case "add":
            self = .add
        case "sub":
            self = .sub
        case "neg":
            self = .neg
        case "eq":
            self = .eq(index)
        case "gt":
            self = .gt(index)
        case "lt":
            self = .lt(index)
        case "and":
            self = .and
        case "or":
            self = .or
        case "not":
            self = .not
        default:
            return nil
        }
    }
    
    func parse() -> String {
        switch self {
        case .add:
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            M=D+M
            """
        case .sub:
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            M=M-D
            """
        case .neg:
            return """
            @SP
            A=M-1
            M=-M
            """
        case .eq(let index):
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            D=M-D
            @EQ.\(index).TRUE
            D;JEQ
            M=0
            @EQ.\(index).END
            0;JMP
            (EQ.\(index).TRUE)
            M=-1
            (EQ.\(index).END)
            """
        case .gt(let index):
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            D=M-D
            @
            D;JGT
            M=0
            @
            0;JMP
            ()
            M=-1
            ()
            """
        case .lt(let index):
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            D=M-D
            @
            D;JLT
            M=0
            @
            0;JMP
            ()
            M=-1
            ()
            """
        case .and:
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            M=D&M
            """
        case .or:
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            M=D|M
            """
        case .not:
            return """
            @SP
            A=M-1
            M=!M
            """
        }
    }
}
