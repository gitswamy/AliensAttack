//
//  GameObjectNode.swift
//  FaceMock
//
//  Created by Swamy on 2/2/16.
//  Copyright © 2016 Ran Tech. All rights reserved.
//

import SpriteKit

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let Star: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
    static let Laser: UInt32 = 0x03
}
/*struct CollisionCategoryBitmask {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Star: UInt32 = 0b1
    static let Player: UInt32 = 0b10
    static let Projectile: UInt32 = 0x02
}*/

enum StarType: Int {
    case Normal = 0
    case Special
}

enum PlatformType: Int {
    case Normal = 0
    case Break
}

class GameObjectNode: SKNode {
    
  func collisionWithPlayer(player: SKNode) -> Bool {
       return false
    }
    
   func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 300.0 {
            self.removeFromParent()
        }
    }

}



class StarNode: GameObjectNode {
    var starType: StarType!
    
   override func collisionWithPlayer(player: SKNode) -> Bool {
        // Boost the player up
      player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 100.0)
   // player.physicsBody?.velocity = CGVector(dx: 100, dy: 100.0)
    print("startType:\(starType)")
        print("hit")
     GameState.sharedInstance.score += (starType == .Normal ? 20 : 100)
    
    // Award stars
    GameState.sharedInstance.stars += (starType == .Normal ? 1 : 5)
    
        // Remove this Star
        self.removeFromParent()
    // Award score
  //  GameState.sharedInstance.score += (starType == .Normal ? 20 : 100)
        
        // The HUD needs updating to show the new stars and score
        return true
    }
}

class PlatformNode: GameObjectNode {
    var platformType: PlatformType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        print("platform")
        // 1
        // Only bounce the player if he's falling
        if player.physicsBody?.velocity.dy < 0 {
            // 2
     //     player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 250.0)
                
            // 3
            // Remove if it is a Break type platform
            if platformType == .Break {
                self.removeFromParent()
            }
        }
        
        // 4
        // No stars for platforms
        return true
    }
}
