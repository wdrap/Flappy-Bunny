//
//  SpriteKitButtonNode.swift
//  Flappy Bunny iOS
//
//  Created by Wim Drapier on 15/01/2021.
//
import SpriteKit

enum AGButtonNodeState {
    case AGButtonNodeStateActive, AGButtonNodeStateSelected, AGButtonNodeStateHidden
}

class AGButtonNode: SKSpriteNode {
    
    // Setup a dummy action closure
    var selectedHandler: () -> Void = { print("No button action set") }
    
    // Button state management
    var state: AGButtonNodeState = .AGButtonNodeStateActive {
        didSet {
            switch state {
            case .AGButtonNodeStateActive:
                // Enable touch
                self.isUserInteractionEnabled = true
                
                // Visible
                self.alpha = 1
                break
            case .AGButtonNodeStateSelected:
                // Semi transparent
                self.alpha = 0.7
                break
            case .AGButtonNodeStateHidden:
                // Disable touch
                self.isUserInteractionEnabled = false
                
                // Hide
                self.alpha = 0
                break
            }
        }
    }
    
    // Support for NSKeyedArchiver (loading objects from SK Scene Editor
    required init?(coder aDecoder: NSCoder) {
        
        // Call parent initializer e.g. SKSpriteNode
        super.init(coder: aDecoder)
        
        // Enable touch on button node
        self.isUserInteractionEnabled = true
    }
}

#if os(iOS) || os(tvOS)
extension AGButtonNode {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .AGButtonNodeStateSelected
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedHandler()
        state = .AGButtonNodeStateActive
    }
}
#endif

#if os(OSX)
extension AGButtonNode {
    
}
#endif
