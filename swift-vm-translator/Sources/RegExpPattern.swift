//
//  RegExpPattern.swift
//  swift-vm-translator
//
//  Created by KokiHirokawa on 2019/03/24.
//  Copyright © 2019 KokiHirokawa. All rights reserved.
//

struct CommandPattern {
    public static let commentOut = "/{2}.*"
    
    public static let unaryFunction = "^(neg|not)$"
    public static let binaryFunction = "^(add|sub|and|or)$"
    public static let comparisonFunction = "^(eq|gt|lt)$"
    // segmentを分割してグループ分けすればパースコードが短くなるはず…
    public static let push = "^push[\\s]+(constant|local|argument|this|that|pointer|temp|static)[\\s]+([\\w]+)$"
    public static let pop = "^pop[\\s]+(local|argument|this|that|pointer|temp|static)[\\s]+([\\w]+)$"
    public static let label = #"^label\s+([\w\._:]+)$"#
    public static let goto = #"^goto\s+([\w\._:]+)$"#
    public static let ifGoto = #"^if-goto\s+([\w\._:]+)$"#
    public static let function = #"^function\s+([\w\._:]+)\s+(\d+)$"#
    public static let call = #"^call\s+([\w\._:]+)\s+(\d+)$"#
    public static let callReturn = "^return$"
    
    public static let filePath = "((.*/)*(.*))\\.vm$"
}

enum CommandType {
    case unaryFunction
    case binaryFunction
    case comparisonFunction
    case push
    case pop
    case label
    case goto
    case ifGoto
    case function
    case call
    case callReturn
}

enum ComparisonFunction {
    case eq(Int)
    case gt(Int)
    case lt(Int)
    
    init?(name: String, index: Int) {
        switch name {
        case "eq":
            self = .eq(index)
        case "gt":
            self = .gt(index)
        case "lt":
            self = .lt(index)
        default:
            return nil
        }
    }
    
    func index() -> Int {
        switch self {
        case .eq(let index), .gt(let index), .lt(let index):
            return index
        }
    }
    
    func parse() -> String {
        var output = """
            @SP
            AM=M-1
            D=M
            A=A-1
            D=M-D
            @EQ.\(index()).TRUE

            """
        
        switch self {
        case .eq:
            output += "D;JEQ\n"
        case .gt:
            output += "D;JGT\n"
        case .lt:
            output += "D;JLT\n"
        }
        
        output += """
            @SP
            A=M-1
            M=0
            @EQ.\(index()).END
            0;JMP
            (EQ.\(index()).TRUE)
            @SP
            A=M-1
            M=-1
            (EQ.\(index()).END)
            """
        return output
    }
}

enum UnaryFunction: String {
    case neg = "neg"
    case not = "not"
    
    func parse() -> String {
        var output = """
            @SP
            A=M-1

            """
        
        switch self {
        case .neg:
            output += "M=-M"
        case .not:
            output += "M=!M"
        }
        
        return output
    }
}

enum BinaryFunction: String {
    case add = "add"
    case sub = "sub"
    case and = "and"
    case or = "or"
    
    func parse() -> String {
        var output = """
            @SP
            AM=M-1
            D=M
            A=A-1

            """
        
        switch self {
        case .add:
            output += "M=D+M"
        case .sub:
            output += "M=M-D"
        case .and:
            output += "M=D&M"
        case .or:
            output += "M=D|M"
        }
        
        return output
    }
}

enum Push: String {
    case constant = "constant"
    case local = "local"
    case argument = "argument"
    case this = "this"
    case that = "that"
    case pointer = "pointer"
    case temp = "temp"
    case `static` = "static"
}

enum Pop: String {
    case local = "local"
    case argument = "argument"
    case this = "this"
    case that = "that"
    case pointer = "pointer"
    case temp = "temp"
    case `static` = "static"
}
