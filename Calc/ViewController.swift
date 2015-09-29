//
//  ViewController.swift
//  Calc
//
//  Created by Michal Plucinski on 2015-07-22.
//  Copyright © 2015 stanford. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var changeSignOutlet: UIButton!
    
    var userIsInTheMiddleOfTypingANumber = false
    var operationStackIsClear = true
    var equalSignPresentInHistory = false
    
    var brain = CalculatorBrain()
    
    @IBAction func appendDigit(sender: UIButton)
    {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTypingANumber {
            if (display.text?.rangeOfString(".") == nil) || (digit != ".") {
                display.text = display.text! + digit
            }
        } else {
            display.text = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    @IBAction func undo(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber
        {
            display.text!.removeAtIndex(display.text!.endIndex.predecessor())
            if display.text!.endIndex == display.text!.startIndex
            {
                displayValue = nil
            }
        } else {
            if let result = brain.undo() {
                displayResult = (result as! String)
            }
            historyValue = brain.description
        }
    }
    
    @IBAction func changeSign(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber {
            if let number = displayValue {
                if number > 0 {
                    display.text = "-" + display.text!
                } else {
                    display.text!.removeAtIndex(display.text!.startIndex)
                }
            } else {
               // displayValue = 0
            }
        } else {
            operate(changeSignOutlet)
        }
    }
    

    @IBAction func operate(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        if let operation = sender.currentTitle
        {
            if let result = brain.performOperation(operation) {
                displayResult = result
            } else {
                displayValue = nil
            }
            historyValue = brain.description
        }
    }
    
    @IBAction func getVariable(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        if let variable = sender.currentTitle {
            brain.pushOperand(variable)
            historyValue = brain.description
        }
    }
    
    @IBAction func setVariable(sender: UIButton)
    {
        if let validVariable = displayValue
        {
            brain.variableValues["M"] = validVariable
            if let result = brain.evaluate() {
                displayValue = result
            }
            userIsInTheMiddleOfTypingANumber = false
        }

    }
    
    @IBAction func enter()
    {
        userIsInTheMiddleOfTypingANumber = false
        if let number = displayValue {
            if let result = brain.pushOperand(number) {
                displayValue = result
                historyValue = brain.description
            } else {
                displayValue = nil
            }
        } else {
            displayValue = nil
        }
    }
    
    @IBAction func clear()
    {
        operationStackIsClear = true
        equalSignPresentInHistory = false
        
        history.text = " "
        displayValue = nil
        
        brain.clearStack()
        brain.variableValues.removeAll()
    }

    var displayResult: AnyObject?
    {
        get
        {
            let possibleNumber = NSNumberFormatter().numberFromString(display.text!)
            
            if let number = possibleNumber {
                return number.doubleValue
            } else if display.text == " " {
                return nil
            } else {
                return display.text!
            }
        }
        set
        {
            if let number = newValue as? Double {
                if let intNum = brain.isIntegerValue(number) {
                    display.text = "\(intNum)"
                } else {
                    display.text = "\(number)"
                }
            } else if let error = newValue as? String {
                display.text = error
            } else {
                display.text = " "
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    var displayValue: Double?
    {
        get {
            if let number = displayResult as? Double {
                return number
            } else {
                return nil
            }
        }
        set {
            if let number = newValue {
                displayResult = number
            } else {
                displayResult = " "
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    var historyValue: String?
    {
        get
        {
            if description == " " {
                return nil
            } else {
                display.text!.removeAtIndex(display.text!.endIndex.predecessor())
                return display.text!
            }
        }
        set
        {
            if let description = newValue {
                history.text = "\(description)="
            } else {
                history.text = " "
            }
            
        }
    }
}

