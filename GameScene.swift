//
//  GameScene.swift
//  FaceMock
//
//  Created by Swamy on 2/2/16.
//  Copyright (c) 2016 Ran Tech. All rights reserved.
//

import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
     //   print("x ,y\(x,y)")
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
     //   print("self\(self)")
        return self / length()
    }
}

private let kAttackerNodeName = "movable"

class GameScene: SKScene, SKPhysicsContactDelegate  {
    
    // Layered Nodes
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var playergroundNode: SKNode!//add to handle player independently
    var hudNode: SKNode!
    
    // Player
    var player: SKNode!
    
    //Attackers
    var attackers: SKNode!
    
 
  
    
    //declare sprites outside
    var backgroundSprite: SKSpriteNode!
    var backgroundNextSprite: SKSpriteNode!
    
    
    var projectile: SKNode!
    
    // To Accommodate iPhone 6
    var scaleFactor: CGFloat!
    
    // Tap To Start node
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    var endLevelY = 0
    
    //To handle touch in common and use in update method
    var touched:Bool = false
    var location = CGPointMake(0, 0)
    var direction = CGPointMake(0, 0)
    
    //laser direction
     var ldirection = CGPointMake(0, 0)
    
    var selectedNode = SKSpriteNode()
    
    //varaible to make sure only one player active
    var selected:Bool = false
    
    //to remove laser if present
    var laserPresent:Bool = false
   
    
    // Labels for score and stars
    var lblScore: SKLabelNode!
    var lblStars: SKLabelNode!
    
    // Max y reached by player
    var maxPlayerY: Int!
    
    // Game over dude!
    var gameOver = false
    
    
    // Time of last frame
    var lastFrameTime : NSTimeInterval = 0
    
    // Time since last frame
    var deltaTime : NSTimeInterval = 0
    
    //laser Node
    var laser: SKNode!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        
        // Reset
        maxPlayerY = 80
        
        GameState.sharedInstance.score = 0
        gameOver = false
        
        
       scaleFactor = self.size.width / 320.0
    
        
        // Create the game nodes
        // Background
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        
        // Add some gravity
       physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        // Set contact delegate
       physicsWorld.contactDelegate = self
        
        // Midground
        midgroundNode = createMidgroundNode()
        addChild(midgroundNode)
        
        // Foreground
        foregroundNode = SKNode()
        addChild(foregroundNode)
      
        //Load the level
        let levelPlist = NSBundle.mainBundle().pathForResource("Level01", ofType: "plist")
        let levelData = NSDictionary(contentsOfFile: levelPlist!)!
        
        //Height at which the player ends the level
        endLevelY   = levelData["EndY"]!.integerValue!
        
       // print("End Level Y\(endLevelY)")
        
        // Add a platform
    // let platform = createPlatformAtPosition(CGPoint(x: 160, y: 320), ofType: .Normal)
    //foregroundNode.addChild(platform)
   
        // Add the platforms
        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        let platformPositions = platforms["Positions"] as! [NSDictionary]
        
        for platformPosition in platformPositions {
            let patternX = platformPosition["x"]?.floatValue
            let patternY = platformPosition["y"]?.floatValue
            let pattern = platformPosition["pattern"] as! NSString
            
            // Look up the pattern
            let platformPattern = platformPatterns[pattern] as! [NSDictionary]
            for platformPoint in platformPattern {
                let x = platformPoint["x"]?.floatValue
                let y = platformPoint["y"]?.floatValue
                let type = PlatformType(rawValue: platformPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let platformNode = createPlatformAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(platformNode)
            }
        }
        

        // Add a star
        
     //   let actualY = random(min: 40, max: size.height - 140/2)
   //    let starnode =
  //    createStarAtPosition(CGPoint(x: 60, y: actualY), ofType: .Special)
        
    //  foregroundNode.addChild(starnode)
        
        // Add the stars
      let stars = levelData["Stars"] as! NSDictionary
        let starPatterns = stars["Patterns"] as! NSDictionary
        let starPositions = stars["Positions"] as! [NSDictionary]
        
        for starPosition in starPositions {
            let patternX = starPosition["x"]?.floatValue
            let patternY = starPosition["y"]?.floatValue
            let pattern = starPosition["pattern"] as! NSString
            
            // Look up the pattern
            let starPattern = starPatterns[pattern] as! [NSDictionary]
            for starPoint in starPattern {
                let x = starPoint["x"]?.floatValue
                let y = starPoint["y"]?.floatValue
                let type = StarType(rawValue: starPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let starNode = createStarAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
              foregroundNode.addChild(starNode)
            }
        }

        // Foreground//updated to playergroundNode
        playergroundNode = SKNode()
        addChild(playergroundNode)
        
        // Add the player
       player = createPlayer("sship")
   //  playergroundNode.addChild(player)
        
      attackers = createAttackers()
      playergroundNode.addChild(attackers)

        
        
        
       
       
        
        // HUD
        hudNode = SKNode()
        // Tap to Start
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
     //   hudNode.addChild(tapToStartNode)
        
        // Build the HUD
        
        // Stars
        // 1
        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: self.size.height-30)
        hudNode.addChild(star)
        
        // 2
        lblStars = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblStars.fontSize = 30
        lblStars.fontColor = SKColor.whiteColor()
        lblStars.position = CGPoint(x: 50, y: self.size.height-40)
        lblStars.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        // 3
        lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
        hudNode.addChild(lblStars)
        
        // Score
        // 4
        lblScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblScore.fontSize = 30
        lblScore.fontColor = SKColor.whiteColor()
        lblScore.position = CGPoint(x: self.size.width-20, y: self.size.height-40)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        
        // 5
        lblScore.text = "0"
        hudNode.addChild(lblScore)
        
       addChild(hudNode)
        
        
    }
    
    func createAttackers() -> SKNode {
        let attackersNode = SKNode()
       // attackersNode.position = CGPoint(x: self.size.width / 4, y: 80.0)//circle
        attackersNode.position = CGPoint(x: self.size.width/4, y: 80.0)//rectangle
        
        //let imageNames = ["bird", "cat", "dog", "turtle", "Tiger", "Cheetah"]
        let imageNames = ["sship","shuttle"]
        for i in 0..<imageNames.count {
            let imageName = imageNames[i]
            
            let sprite = SKSpriteNode(imageNamed: imageName)
            sprite.name = imageName
       //     print("sprite name \(sprite.name)")
            
            let offsetFraction = (CGFloat(i) + 1.0)/(CGFloat(imageNames.count) + 1.0)
           // print("offsetFraction\(offsetFraction)")
            let positionOfAttackers = size.height/50
           // print("positionOfAttackers\(positionOfAttackers)")
            sprite.position = CGPoint(x: size.width * offsetFraction, y: size.height / 50)
             attackersNode.addChild(sprite)
           
        }
        return attackersNode
       
    }
    override func didMoveToView(view: SKView) {

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        
       for touch in touches {
          let positionInScene = touch.locationInNode(self)
     //   print("touch Began\(positionInScene)")

       // print("selected touch:\(selected)")
        if(!selected){//add condition to always select player if its not there
            selectNodeForTouch(positionInScene)
        }
 
        }
      
            // 2
        // Remove the Tap to Start node
        tapToStartNode.removeFromParent()
        
        // 3
        // Start the player by putting them into the physics simulation
      player.physicsBody?.dynamic = true
        
        // 4
     // player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 10.0))
        
        
        touched = true
        for touch in touches {
            location = touch.locationInNode(self)
         
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
       
        for touch in touches {
            location = touch.locationInNode(self)
           
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
 
        // First, update the delta time values:
        
        // If we don't have a last frame time value, this is the first frame,
        // so delta time will be zero.
        if lastFrameTime <= 0 {
            lastFrameTime = currentTime
        }
        
        // Update delta time
        deltaTime = currentTime - lastFrameTime
        
        // Set last frame time to current time
        lastFrameTime = currentTime
     //   print("deltaTime\(deltaTime)")
        
        // Next, move each of the four pairs of sprites.
        // Objects that should appear move slower than foreground objects.
        self.moveSprite(backgroundSprite, nextSprite:backgroundNextSprite, speed:10.0)
        
        
   //     print("player position:\(player.position.y)")
     //    print("foreground position:\(foregroundNode.position.y)")
      //   print("background position:\(backgroundNode.position.y)")
        //print("playerground position:\(playergroundNode.position.y)")
        
        if gameOver {
            return
        }
        
        // Remove game objects that have passed by
        foregroundNode.enumerateChildNodesWithName("NODE_PLATFORM", usingBlock: {
            (node, stop) in
            let platform = node as! PlatformNode
            platform.checkNodeRemoval(self.player.position.y)
        })
        
        foregroundNode.enumerateChildNodesWithName("NODE_STAR", usingBlock: {
            (node, stop) in
            let star = node as! StarNode
            star.checkNodeRemoval(self.player.position.y)
        })
        
        if (touched ) {
            

        //    backgroundNode.position = CGPoint(x: 0.0, y: -backgroundNode.position.y.distanceTo(1))
            midgroundNode.position = CGPoint(x: 0.0, y: -midgroundNode.position.y.distanceTo(2))
            foregroundNode.position = CGPoint(x: 0.0,y: -foregroundNode.position.y.distanceTo(3))
           

        }
    
        // 1
        // Check if we've finished the level
        if Int(-(foregroundNode.position.y)) > endLevelY {
           endGame()
        }
        
        // 2
        // Check if we've fallen too far
        if Int(player.position.y) < maxPlayerY - 400 {
            endGame()
        }

        
          }
    
    func createBackgroundNode() -> SKNode {
        // 1
        // Create the node
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        // 2
        // Go through images until the entire background is built
     //  for index in 0...19 {
            // 3
          //  let backgroundSprite = SKSpriteNode(imageNamed:String(format: "Background%02d", index + 1))//commented for globarl varaible
          //  backgroundSprite = SKSpriteNode(imageNamed:String(format: "Background%02d", index + 1))// commented for single image
        
        backgroundSprite = SKSpriteNode(texture:
            SKTexture(imageNamed: "Background@2x"))//added for single image
            //adding next frame for parallaxation
        
        backgroundSprite.setScale(scaleFactor)
        backgroundSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
          // node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
       // print("CGFloat index\(CGFloat(1))")
        
         backgroundSprite.position = CGPoint(x: self.size.width / 2, y: ySpacing * 0.0)
        
            backgroundNextSprite = backgroundSprite.copy() as! SKSpriteNode
            
            // 4
         //
            backgroundNextSprite.setScale(scaleFactor)
           //
           backgroundNextSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
          //  backgroundSprite.position = CGPoint(x: self.size.width / 2, y: ySpacing * self.size.height / 2)
            
           backgroundNextSprite.position = CGPoint(x: backgroundSprite.position.x , y:  (backgroundSprite.position.y + backgroundSprite.size.height))
            
            //5
            backgroundNode.addChild(backgroundSprite)
          backgroundNode.addChild(backgroundNextSprite)
     //   }
        
        // 6
        // Return the completed background node
        return backgroundNode
    }
    
    func createPlayer(type: String) -> SKNode {
    //func createPlayer() -> SKNode {
        let playerNode = SKNode()
        
      //  playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)//circle shape
        playerNode.position = CGPoint(x: self.size.width/2, y: 80.0)//added this for rectangle shape
        
        //let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
       //  let imageNames = ["bird", "cat", "dog", "turtle", "Tiger", "Cheetah"]
       // print("type:\(type)")
        
      //  if(type.texture == imageNames[0]){// alter this condition to fit ,instead of textture
      //  let sprite = SKSpriteNode(imageNamed: imageNames[0])
       
        let sprite = SKSpriteNode(imageNamed: type)
      //  print("player sprite\(sprite)")
        
   

        playerNode.addChild(sprite)
        //}
    
        
        // 1
     //   node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
 /*       playerNode.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)//rectangle
      //  playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)//circle
        // 2
        playerNode.physicsBody?.dynamic = false
        // 3
    
        // 1
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        // 2
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        // 3
        playerNode.physicsBody?.collisionBitMask = 0
        // 4
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform
*/
        return playerNode
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        movePlayerToLocation()
    
         }
    
    func createStarAtPosition(position: CGPoint, ofType type: StarType) -> StarNode {
        
        // 1
        let node = StarNode()
        
        let thePosition = CGPoint(x: position.x * scaleFactor, y:   position.y)
        node.position = thePosition
        node.name = "NODE_STAR"
        
        node.starType = type
       var star: SKSpriteNode
        if type == .Special {
            star = SKSpriteNode(imageNamed: "StarSpecial")
       } else {
            star = SKSpriteNode(imageNamed: "Star")
       }
      node.addChild(star)
 
        
        
        
        // 3
        node.physicsBody = SKPhysicsBody(circleOfRadius: star.size.width / 2)
        
        // 4
        node.physicsBody?.dynamic = true
        node.physicsBody?.usesPreciseCollisionDetection = true
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Star
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Laser // 4
        
       return node
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        // 1
        var updateHUD = false
     
      //  if(selected){
        // 2
       let whichNode = (contact.bodyA.node != laser) ? contact.bodyA.node : contact.bodyB.node
      let other = whichNode as! GameObjectNode
      //  print("other\(other)")
        
        if(other.name == "NODE_PLATFORM") {
          //  player.removeFromParent()
           print("hit platform:change the player")
            
            player.removeFromParent()
          laser.removeFromParent()
            
            selected = false
            
            //show a spark effect
            let spark = SKSpriteNode(imageNamed: "spark")
            //   if projectile.position == monster.position{
         //   print("spark")
            spark.position = player.position
            spark.zPosition = 60
            addChild(spark)
            let fadeAndScaleAction = SKAction.group([
                SKAction.fadeOutWithDuration(0.2),
                SKAction.scaleTo(0.1, duration: 0.2)])
            let cleanUpAction = SKAction.removeFromParent()
            spark.runAction(SKAction.sequence([fadeAndScaleAction, cleanUpAction]))
            
           
        //    print("selected platform:\(selected)")
           // player = createPlayer()//need to pass type of new player as parameter
            //playergroundNode.addChild(player)
        }
        if(other.name == "NODE_STAR") {
            //  player.removeFromParent()
          print("Alien  hit")
            
          laser.removeFromParent()
            
            //show a spark effect
            let spark = SKSpriteNode(imageNamed: "spark")
            //   if projectile.position == monster.position{
        //    print("spark")
            spark.position = laser.position
            spark.zPosition = 60
            addChild(spark)
            let fadeAndScaleAction = SKAction.group([
                SKAction.fadeOutWithDuration(0.2),
                SKAction.scaleTo(0.1, duration: 0.2)])
            let cleanUpAction = SKAction.removeFromParent()
            spark.runAction(SKAction.sequence([fadeAndScaleAction, cleanUpAction]))
            
           // selected = false
         //   print("selected star:\(selected)")
            
        }

        
            updateHUD = other.collisionWithPlayer(player)
        
    
        // Update the HUD if necessary
        if updateHUD {
            // 4 TODO: Update HUD in Part 2
           lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
          lblScore.text = String(format: "%d", GameState.sharedInstance.score)
        }
        
        
        //**********Collision Alien(star) with laser*******
        
 /*       let whichNodeLaserHit = (contact.bodyA.node != laser) ? contact.bodyA.node : contact.bodyB.node
        let otherNodeLaserHit = whichNodeLaserHit as! GameObjectNode
        print("otherNodeLaserHit\(otherNodeLaserHit)")
        
        if(otherNodeLaserHit.name == "NODE_STAR") {
            //  player.removeFromParent()
            print("Alien  hit")
            
            laser.removeFromParent()
            
            //show a spark effect
            let spark = SKSpriteNode(imageNamed: "spark")
            //   if projectile.position == monster.position{
            print("spark")
            spark.position = laser.position
            spark.zPosition = 60
            addChild(spark)
            let fadeAndScaleAction = SKAction.group([
                SKAction.fadeOutWithDuration(0.2),
                SKAction.scaleTo(0.1, duration: 0.2)])
            let cleanUpAction = SKAction.removeFromParent()
            spark.runAction(SKAction.sequence([fadeAndScaleAction, cleanUpAction]))
            
            selected = false
            print("selected platform:\(selected)")
            
        }
        
        updateHUD = otherNodeLaserHit.collisionWithPlayer(laser)
        
        
        // Update the HUD if necessary
        if updateHUD {
            // 4 TODO: Update HUD in Part 2
            lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
            lblScore.text = String(format: "%d", GameState.sharedInstance.score)
        }
*/
        
        
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func randomPoint(scene: CGRect) -> CGPoint {
        let x = CGFloat(arc4random_uniform(UInt32(scene.width)))
        let y = CGFloat(arc4random_uniform(UInt32(scene.height)))
        return CGPoint(x: x, y: y)
    }
    
     func projectileDidCollideWithMonster(lion:SKSpriteNode, star:SKSpriteNode) {
      //  print("Hit")
       lion.removeFromParent()
      //  star.removeFromParent()
    }
    
    func createPlatformAtPosition(position: CGPoint, ofType type: PlatformType) -> PlatformNode {
        // 1
        let node = PlatformNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_PLATFORM"
        node.platformType = type
        
        // 2
        var sprite: SKSpriteNode
        if type == .Break {
            sprite = SKSpriteNode(imageNamed: "PlatformBreak")
        } else {
            sprite = SKSpriteNode(imageNamed: "Platform")
        }
        node.addChild(sprite)
        
        // 3
        
     
        node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        node.physicsBody?.dynamic = true
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Laser
        
        return node
    }
    
    func createMidgroundNode() -> SKNode {
        // Create the node
        let theMidgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat!
        
        // 1
        // Add some branches to the midground
        for index in 0...9 {
            var spriteName: String
            // 2
            let r = arc4random() % 2
            if r > 0 {
                spriteName = "BranchRight"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = self.size.width
            } else {
                spriteName = "BranchLeft"
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition = 0.0
            }
            // 3
            let branchNode = SKSpriteNode(imageNamed: spriteName)
            branchNode.anchorPoint = anchor
            branchNode.position = CGPoint(x: xPosition, y: 500.0 * CGFloat(index))
            theMidgroundNode.addChild(branchNode)
        }
        
        // Return the completed midground node
        return theMidgroundNode
    }
    
    override func didSimulatePhysics() {
        // 1
        // Set velocity based on x-axis acceleration
      //  player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        // 2
        // Check x bounds
    /*    if player.position.x < -20.0 {
            player.position = CGPoint(x: self.size.width + 20.0, y: player.position.y)
        } else if (player.position.x > self.size.width + 20.0) {
            player.position = CGPoint(x: -20.0, y: player.position.y)
        }*/
    }
    
    //move the player based on the touch
    // Move the node to the location of the touch
    func movePlayerToLocation() {
   
        if(laserPresent){
          laser.removeFromParent()
        }
        
        
        
        //laser
        let laserNode = SKNode()
        // laserNode.position = CGPoint(x: self.size.width/2, y: 80.0)
        laserNode.position = CGPoint(x: player.position.x, y: player.position.y)
        
        //   let laserSprite = SKSpriteNode(imageNamed: "laser")
        // laserNode.addChild(laserSprite)
        //  print("player name\(selectedNode.name!)")
       print("movePlayer selected \(selected)")
        if(selected){
            if( "shuttle" == selectedNode.name! ){
                laser = createLaser("beam")
            }
            else if( "sship" == selectedNode.name! ){
                laser = createLaser("laser")
            }
            
            playergroundNode.addChild(laser)
            laserPresent = true
        
        
        // laser = createLaser("beam")
        //  if(selected){
        //playergroundNode.addChild(laser)
        //}
        
        

        
        // How fast to move the node
        let speed = 50 as CGFloat
        //laser speed
         let lspeed = 800 as CGFloat
        
        // Compute vector components in direction of the touch
        var dx = location.x - player.position.x
        //laser x
        var ldx = location.x - laser.position.x
        
        var dy = location.y - player.position.y
        //laser y
        var ldy = location.y - laser.position.y
        
        let mag = sqrt(dx*dx+dy*dy)
        
        //laser mag
        let lmag = sqrt(ldx*ldx+ldy*ldy)
        
        // Normalize and scale
        dx = dx/mag * speed
        dy = dy/mag * speed
        
        //lasr Normalize and scale
       ldx = ldx/lmag * lspeed
       ldy = ldy/lmag * lspeed
        
        //angle
        var shipAngle: CGFloat
        shipAngle = atan2(dy,dx) - degToRad(90.0)
        //Normalize the angle
        if shipAngle < 0 { shipAngle += 6.28319 }//360 deg = 6.28319 radians
       // print("shipAngle\(shipAngle)")
        
        var laserAngle: CGFloat
        laserAngle = (atan2(ldy,ldx)) - degToRad(90.0)
        if laserAngle < 0 { laserAngle += 6.28319 }
       //  print("laserAngle\(laserAngle)")
        
       direction = CGPointMake(player.position.x+dx, player.position.y+dy)
       
        //laser direction
        ldirection = CGPointMake(laser.position.x+ldx, laser.position.y+ldy)
        
        let actionMove = SKAction.moveTo(direction, duration: 2.0)
        let actionTurn = SKAction.rotateByAngle(shipAngle , duration:0)
       
        //laser action move
       let lactionMove = SKAction.moveTo(ldirection, duration: 2.0)
        let lactionTurn = SKAction.rotateByAngle(laserAngle , duration:0)
        
        //  let actionMoveDone = SKAction.removeFromParent()
       player.runAction(SKAction.sequence([actionTurn,actionMove]))
       // player.runAction(actionMove)
        
        //laser.runAction(lactionMove)
        
        //laser run action
     // laser.runAction(lactionMove)
         laser.runAction(SKAction.sequence([lactionTurn,lactionMove]))
      
     //   let action = SKAction.rotateByAngle(mag, duration:1)
        
      //  sprite.runAction(SKAction.repeatAction(lmag, count: 1))// repeatActionForever(action))
        
        
       // playergroundNode.runAction(actionMove)
        
     //
        
    
        }//if selected close
        
    }
    
    func degToRad(degree: Double) -> CGFloat {
        return CGFloat(Double(degree) / 180.0 * M_PI)
    }
    
    func selectNodeForTouch(touchLocation: CGPoint) {
       

        // 1
        let touchedNode = self.nodeAtPoint(touchLocation)
        
        if touchedNode is SKSpriteNode {
            // 2
            if !selectedNode.isEqual(touchedNode) {
                selectedNode.removeAllActions()
                selectedNode.runAction(SKAction.rotateToAngle(0.0, duration: 0.1))
                
                selectedNode = touchedNode as! SKSpriteNode
               print("selectedNode\(selectedNode)")
             //   print("touchedNode\(touchedNode)")
                
              //  let imageNames = ["bird", "cat", "dog", "turtle", "Tiger", "Cheetah"]
                let imageNames = ["sship","shuttle"]
                for i in 0..<imageNames.count {
                    if( selectedNode.name == imageNames[i])
                    {
                         player = createPlayer(selectedNode.name!)
                       
                //        print("player\(player)")
                        let sequence = SKAction.sequence([SKAction.rotateByAngle(degToRad(-4.0), duration: 0.1),
                            SKAction.rotateByAngle(0.0, duration: 0.1),
                            SKAction.rotateByAngle(degToRad(4.0), duration: 0.1)])
                        selectedNode.runAction(SKAction.repeatActionForever(sequence))
                        
                        selected = true
                        playergroundNode.addChild(player)
                    }
                 
                }
                
             //   playergroundNode.addChild(laser)
                
             
                
          
              
                
                
                
                
            
             //   print("selected selct:\(selected)")
  
            }
        }
    }
    
    
    func endGame() {
        // 1
        gameOver = true
        
        // 2
        // Save stars and high score
        GameState.sharedInstance.saveState()
        
        // 3
        let reveal = SKTransition.fadeWithDuration(0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
    //Move a pair of sprites leftwards based on a speed value
    //when either of sprites goes off-screen, move it 
    //right so that it appears to be seamless movement
    func moveSprite(sprite: SKSpriteNode, nextSprite: SKSpriteNode, speed:Float) -> Void {
        var newPosition = CGPointZero
      //  print("sprite\(sprite)")
    //    print("nextSprite\(nextSprite)")
        
        for spriteToMove in [sprite, nextSprite]{
            //Shift the sprite leftward based on the speed
            newPosition = spriteToMove.position
           // newPosition.x -= CGFloat(speed * Float(deltaTime))//moves horizontally
            newPosition.y -= CGFloat(speed * Float(deltaTime))
            spriteToMove.position = newPosition
            
            // If this sprite is now offscreen (i.e., its rightmost edge is
            // farther left than the scene's leftmost edge):
         /*   if spriteToMove.frame.maxX < self.frame.minX {
                
                // Shift it over so that it's now to the immediate right
                // of the other sprite.
                // This means that the two sprites are effectively
                // leap-frogging each other as they both move.
                spriteToMove.position =
                    CGPoint(x: spriteToMove.position.x +
                        spriteToMove.size.width * 2,
                        y: spriteToMove.position.y)
            }*/
            
            // If this sprite is now offscreen (i.e., its topmost edge is
            // farther top than the scene's topmost edge):
            if spriteToMove.frame.maxY <  self.frame.minY {
                
                // Shift it over so that it's now to the immediate bottom
                // of the other sprite.
                // This means that the two sprites are effectively
                // leap-frogging each other as they both move.
                spriteToMove.position =
                    CGPoint(x: spriteToMove.position.x,
                        y: spriteToMove.position.y  +
                            spriteToMove.size.height * 2)
            }
        
        }
    }
    
    func createLaser(type: String) -> SKNode {
        let laserNode = SKNode()
        // laserNode.position = CGPoint(x: self.size.width/2, y: 80.0)
        laserNode.position = CGPoint(x: player.position.x, y: player.position.y)
        
       
        let laserSprite = SKSpriteNode(imageNamed: type)
        laserNode.addChild(laserSprite)
        
        
        // 1
        //   node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
   laserNode.physicsBody = SKPhysicsBody(rectangleOfSize: laserSprite.size)//rectangle
        //  playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)//circle
        // 2
       laserNode.physicsBody?.dynamic = false
        // 3
        
        // 1
        laserNode.physicsBody?.usesPreciseCollisionDetection = true
        // 2
      laserNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Laser
        // 3
      laserNode.physicsBody?.collisionBitMask = 0
        // 4
      laserNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Platform | CollisionCategoryBitmask.Star
        
       return laserNode
    }

}
