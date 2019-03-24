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

enum Arithmetic: String {
    case add = "add"
    case sub = "sub"
    case neg = "neg"
    case eq = "eq"
    case gt = "gt"
    case lt = "lt"
    case and = "and"
    case or = "or"
    case not = "not"
    
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
        case .eq:
            return """
            @SP
            AM=M-1
            D=M
            A=A-1
            D=M-D
            @
            D;JEQ
            M=0
            @
            0;JMP
            ()
            M=-1
            ()
            """
        case .gt:
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
        case .lt:
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
