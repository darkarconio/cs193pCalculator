//
//  CalculatorBrain.swift
//  
//
//  Created by Michal Plucinski on 2015-07-24.
//
//

import Foundation

class CalculatorBrain
{
    private enum Op: CustomStringConvertible
    {
        case Operand(Double)
        case Variable(String)
        case UnaryOperation(String, Double -> Double, (Double -> String?)? )
        case BinaryOperation(String, Int, (Double, Double) -> Double, ((Double, Double) -> String?)? )
        case ConstantOperand(String, Double)
        
        var description: String {
            get
            {
                switch self
                {
                case Operand(let operand):
                    return "\(operand)"
                case Variable(let variable):
                    return variable
                case UnaryOperation(let symbol, _, _):
                    return symbol
                case BinaryOperation(let symbol, _, _, _):
                    return symbol
                case ConstantOperand(let symbol, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            switch self
            {
            case BinaryOperation(_, let priority, _, _):
                return priority
            default:
                return Int.max
            }
        }
    }
    
    private var opStack = [Op]()
    
    private var knownOps = [String:Op]()
    
    init()
    {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.BinaryOperation("×", 1, *, nil))
        learnOp(Op.BinaryOperation("÷", 1, { $1 / $0 }) { denominator, _ in return denominator == 0 ? "Division by zero" : nil } )
        learnOp(Op.BinaryOperation("+", 0, +, nil))
        learnOp(Op.BinaryOperation("−", 0, { $1 - $0 }, nil) )
        learnOp(Op.UnaryOperation("√", sqrt) { $0 < 0 ? "Sqrt of negative number" : nil } )
        learnOp(Op.UnaryOperation("sin", sin, nil))
        learnOp(Op.UnaryOperation("cos", cos, nil))
        learnOp(Op.UnaryOperation("±", -, nil))
        learnOp(Op.ConstantOperand("π", M_PI))
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList { // guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    func isIntegerValue (num: Double) -> Int? {return floor(num) == num ? Int(num) : nil}

    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op], error: String?)
    {
        if !ops.isEmpty
        {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op
            {
            case .Operand(let operand):
                return (operand, remainingOps, nil)
            case .Variable(let variable):
                if let operand = variableValues[variable] {
                    return (operand, remainingOps, nil)
                } else {
                    return (nil, remainingOps, "Variable unset")
                }
            case .ConstantOperand(_, let operand):
                return (operand, remainingOps, nil)
            case .UnaryOperation(_, let operation, let errorCheck):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result
                {
                    if let error = errorCheck?(operand) {
                        return (nil, operandEvaluation.remainingOps, error)
                    } else {
                        return (operation(operand), operandEvaluation.remainingOps, nil)
                    }
                } else if let error = operandEvaluation.error {
                    return (nil, ops, error)
                }
            case .BinaryOperation(_, _, let operation, let errorCheck):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result
                {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result
                    {
                        if let error = errorCheck?(operand1, operand2) {
                            return (nil, op2Evaluation.remainingOps, error)
                        } else {
                            return (operation(operand1, operand2), op2Evaluation.remainingOps, nil)
                        }
                    } else if let error = op2Evaluation.error {
                        return (nil, ops, error)
                    }
                } else if let error = op1Evaluation.error {
                    return (nil, ops, error)
                }
            }
        }
        return (nil, ops, "Not enough operands")
    }
    
    private func describe(ops: [Op]) -> (description: String, remainingOps: [Op], precedence: Int)
    {
        if !ops.isEmpty
        {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op
            {
            case .Operand(let operand):
                if let intOperand = isIntegerValue(operand) {
                    return ("\(intOperand)", remainingOps, op.precedence)
                } else {
                    return ("\(operand)", remainingOps, op.precedence)
                }
            case .Variable(let variable):
                return (variable, remainingOps, op.precedence)
            case .ConstantOperand(let symbol, _):
                return ("\(symbol)", remainingOps, op.precedence)
            case .UnaryOperation(let symbol, _, _):
                let operandEvaluation = describe(remainingOps)
                let newDescription = symbol + "(\(operandEvaluation.description))"
                return (newDescription, operandEvaluation.remainingOps, op.precedence)
            case .BinaryOperation(let symbol, let priority, _, _):
                func describeWithBrackets (ops: [Op]) -> (description: String, remainingOps: [Op])
                {
                    let opEvaluation = describe(ops)
                    var operand = opEvaluation.description
                    if priority > opEvaluation.precedence {
                        operand = "(\(operand))"
                    }
                    return (operand, opEvaluation.remainingOps)
                }
                let op1Evaluation = describeWithBrackets(remainingOps)
                let op2Evaluation = describeWithBrackets(op1Evaluation.remainingOps)
                let newDescription = "\(op2Evaluation.description)" + symbol + "\(op1Evaluation.description)"
                return (newDescription, op2Evaluation.remainingOps, priority)
            }
        }
        return ("?", ops, Int.max)
    }
    
    var description: String
    {
        get
        {
            let evaluation = describe(opStack)
            var result = evaluation.description
            
            for var remainingEvaluation = describe(evaluation.remainingOps);
                    remainingEvaluation.description != "?";
                    remainingEvaluation = describe(remainingEvaluation.remainingOps) {
                result = "\(remainingEvaluation.description)," + result
            }
            return result
        }
    }
    
    var variableValues = [String:Double]()

    func evaluate() -> Double?
    {
        let (result, remainder, _) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainder) left over, described \(description)")
        return result
    }
    
    func evaluateAndReportErrors() -> AnyObject
    {
        let (result, _, error) = evaluate(opStack)
        if result != nil {return result!}
        else {return error!}
    }
    
    func clearStack()
    {
        opStack.removeAll()
    }
    
    func pushOperand(operand: Double) -> Double?
    {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double?
    {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    func performOperation(symbol: String) -> AnyObject?
    {
        if let operation = knownOps[symbol]
        {
            opStack.append(operation)
        }
        return evaluateAndReportErrors()
    }
    
    func undo() -> AnyObject?
    {
        opStack.removeLast()
        return evaluateAndReportErrors()
    }
}