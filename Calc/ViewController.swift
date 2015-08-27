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
    
    @IBAction func backspace(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber
        {
            display.text = dropLast(display.text!)
            if count(display.text!) == 0
            {
                displayValue = nil
            }
        }
    }
    
    @IBAction func changeSign(sender: UIButton)
    {
        if userIsInTheMiddleOfTypingANumber {
            if let number = displayValue {
                if number > 0 {
                    display.text = "-" + display.text!
                } else {
                    display.text = dropFirst(display.text!)
                }
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
            addToHistory("\(operation)", operation: true)
            
            if let result = brain.performOperation(operation) {
                displayValue = result
            } else {
                displayValue = nil
            }
        }
    }
    
    @IBAction func enter()
    {
        userIsInTheMiddleOfTypingANumber = false
        if let number = displayValue {
            if let result = brain.pushOperand(number) {
                displayValue = result
                addToHistory("\(result)", operation: false)
            } else {
                displayValue = nil
            }
        } else {
            displayValue = nil
        }
    }
    
    func addToHistory (addition: String, operation: Bool)
    {
        var equalSign = ""
        
        if equalSignPresentInHistory {
            history.text = dropLast(history.text!)
            history.text = dropLast(history.text!)
            equalSignPresentInHistory = false
        }
        
        if operation {
            equalSign = " ="
            equalSignPresentInHistory = true
        }
        
        if operationStackIsClear {
            history.text = addition + equalSign
            operationStackIsClear = false
        } else {
            history.text = history.text! + " \(addition)" + equalSign
        }
    }
    
    
    @IBAction func clear()
    {
        operationStackIsClear = true
        
        history.text = "\(0)"
        displayValue = nil
        
        brain.clearStack()
    }

    var displayValue: Double?
    {
        get {
            var possibleNumber = NSNumberFormatter().numberFromString(display.text!)
            
            if let number = possibleNumber {
                return number.doubleValue
            } else {
                return nil
            }
        }
        set {
            if let number = newValue {
                display!.text = "\(number)"
            }
            else {
                display!.text = "\(0)"
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
}

