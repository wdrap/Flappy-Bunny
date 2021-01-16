//
//  GameScene.swift
//  Flappy Bunny Shared
//
//  Created by Wim Drapier on 09/01/2021.
//
import SpriteKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene {
    
    fileprivate var gameState: GameSceneState = .active
    fileprivate var hero: SKSpriteNode!
    fileprivate var sinceTouch : CFTimeInterval = 0
    fileprivate let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    fileprivate let scrollSpeed: CGFloat = 100
    fileprivate var scrollLayer: SKNode!
    fileprivate var obstacleLayer: SKNode!
    fileprivate var obstacleSource: SKNode!
    fileprivate var spawnTimer: CFTimeInterval = 0
    fileprivate var restartButton: AGButtonNode!
    fileprivate var scoreLabel: SKLabelNode!
    fileprivate var points = 0
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
  
    func scrollWorld() {
        // Scroll World
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        // Loop through scroll layer nodes
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            // Get ground node position, convert node position to scene space
            let groundPosition = scrollLayer.convert(ground.position, to: self)
            
            // Check if ground sprite has left the scene
            if groundPosition.x <= -ground.size.width / 2 {
                
                // Reposition ground sprite to the second starting position
                let newPosition = CGPoint(x: (self.size.width / 2) + ground.size.width, y: groundPosition.y)
                
                // Convert new node position back to scroll layer space
                ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func updateObstacles() {
        // Update Obstacles
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        // Loop through obstacle layer nodes
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            // Get obstacle node position, convert node position to scene space
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            // Check if obstacle has left the scene
            if obstaclePosition.x <= -26 {
                // 26 is one half the width of an obstacle
                
                // Remove obstacle node from obstacle layer
                obstacle.removeFromParent()
            }
        }
        
        // Time to add a new obstacle?
        if spawnTimer >= 1.5 {
            
            // Create a new obstacle by copying the source obstacle
            let newObstacle = obstacleSource.copy() as! SKNode
            obstacleLayer.addChild(newObstacle)
            
            // Generate new obstacle position, start just outside screen and with a random y value
            let randomPosition =  CGPoint(x: 347, y: CGFloat.random(in: 234...382))
            
            // Convert new node position back to obstacle layer space
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
    }
    
    #if os(watchOS)
    override func sceneDidLoad() {
        //        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        // Set physics contact delegate
        physicsWorld.contactDelegate = self
        
        //        self.setUpScene()
        hero = (childNode(withName: "//hero") as! SKSpriteNode)
        hero.isPaused = false
        
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        // Set reference to obstacle layer node
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        // Set reference to obstacle Source node
        obstacleSource = self.childNode(withName: "//obstacle")
        
        restartButton = (self.childNode(withName: "restartButton") as! AGButtonNode)
        
        // Setup restart button selection handler
        restartButton.selectedHandler = {
            
            // Grab reference to our SpriteKit view
            let skView = self.view as SKView?
            
            // Load Game scene
            let scene = GameScene(fileNamed:"GameScene") as GameScene?
            
            // Ensure correct aspect mode
            scene?.scaleMode = .aspectFill
            
            // Restart game scene
            skView?.presentScene(scene)
        }
        
        // Hide restart button
        restartButton.state = .AGButtonNodeStateHidden
        
        scoreLabel = (self.childNode(withName: "scoreLabel") as! SKLabelNode)
        
        // Reset Score label
        scoreLabel.text = "\(points)"
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        // Skip game update if game no longer active
        if gameState != .active { return }
        
        // Called before each frame is rendered
        // Grab current velocity
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        // Check and cap vertical velocity
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        // Apply falling rotation
        if sinceTouch > 0.2 {
            let impulse = -20000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        // Clamp rotation
        hero.zRotation.clamp(v1: CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(v1: -1, 3)
        
        // Update last touch timer
        sinceTouch += fixedDelta
        
        spawnTimer+=fixedDelta
        
        // Process world scrolling
        scrollWorld()
        updateObstacles()
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Hero touches anything, game over
        
        // Ensure only called while game running
        if gameState != .active { return }
        
        // Get references to bodies involved in collision
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        // Get references to the physics body parent nodes
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        // Did our hero pass through the 'goal'
        if nodeA.name == "goal" || nodeB.name == "goal" {
            
            // Increment points
            points += 1
            
            // Update score label
            scoreLabel.text = String(points)
            
            // We can return now
            return
        }
        
        // Change game state to game over
        gameState = .gameOver
        
        // Stop any new angular velocity being applied
        hero.physicsBody?.allowsRotation = false
        
        // Reset angular velocity
        hero.physicsBody?.angularVelocity = 0
        
        // Stop hero flapping animation
        hero.removeAllActions()
        
        // Create our hero death action
        let heroDeath = SKAction.run({
            
            // Put our hero face down in the dirt
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
        })
        
        // Run action
        hero.run(heroDeath)
        
        // Load the shake action resource
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        // Loop through all nodes
        for node in self.children {
            
            // Apply effect each ground node
            node.run(shakeScene)
        }
        
        // Show restart button
        restartButton.state = .AGButtonNodeStateActive
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Disable touch if game state is not active
        if gameState != .active { return }
        
        // Reset velocity, helps improve response against cumulative falling velocity
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
        // Apply subtle rotation
        hero.physicsBody?.applyAngularImpulse(1)
        
        // Reset touch timer
        sinceTouch = 0
    }
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    
    override func mouseDown(with event: NSEvent) {
      
    }
    
    override func mouseDragged(with event: NSEvent) {
    
    }
    
    override func mouseUp(with event: NSEvent) {
    }
    
}
#endif

