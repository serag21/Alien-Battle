//
//  GameScene.swift
//  Space Battle
//
//  Created by Serag Sorror on 12/28/20.
//

import SpriteKit
import GameplayKit

var gameScore = 0

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let scoreLabel = SKLabelNode(fontNamed: "street cred")
    
    var livesNumber = 3
    var livesLabel = SKLabelNode(fontNamed: "street cred")
    
    var levelNumber = 0
    
    
    //Initiate player object
    let player = SKSpriteNode(imageNamed: "playerShip3")
    
    //Initiate sounds
    let bulletSound = SKAction.playSoundFileNamed("bulletSound.wav", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosionSound.wav", waitForCompletion: false)
    let gainLifeSound = SKAction.playSoundFileNamed("gainLifeSound2.wav", waitForCompletion: false)
    
    let tapToStartLabel = SKLabelNode(fontNamed: "street cred")
    
    //Menu, in game, and gameover states
    enum gameState {
        case preGame //Game state is before start of game
        case inGame //Game state is during game
        case afterGame //Game state is after the game
    }
    
    var currentGameState = gameState.preGame
    
    //Set up different types of physics (can't do 3 b/c tha'ts Player + Bullet)
    struct PhysicsCategories{
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1 //1
        static let Bullet : UInt32 = 0b10 //2
        static let Enemy : UInt32 = 0b100 //4
        static let Life: UInt32 = 0b111//7
        static let EnemyBullet: UInt32 = 0b1111//15
    }
    
    //This logic generates a random number given a max & min(used to dictate where enemy ships go)
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    //Set up game area as a rectangle
    var gameArea: CGRect
    //Setting up game area to be size of screen that applies to All apple devices b/c Ipad can see more WIDTH (not height) than Iphone
    override init(size: CGSize) {
        
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //This function starts when as soon as the screen moves into view (on startup for Ingame state)
    override func didMove(to view: SKView) {
        
        //always initialize gameScore to 0 b/c it's declared globally
        gameScore = 0
        
        self.physicsWorld.contactDelegate = self
        
        for i in 0...1{
        
        //Set's the background to center of screen
        let background = SKSpriteNode(imageNamed: "background")
        background.size = self.size
        background.anchorPoint = CGPoint(x: 0.5, y: 0)
        background.position = CGPoint(x: self.size.width/2, y: self.size.height*CGFloat(i))
        background.zPosition = 0
        background.name = "Background"
        self.addChild(background)
        }
        
        player.setScale(1.5) //change size based on scale (1 = regular size)
        player.position = CGPoint(x: self.size.width/2, y: 0 - player.size.height)
        player.zPosition = 2 //Want bullet to start underneath the ship so ship is third layer
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 80
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width * 0.15, y: self.size.height + scoreLabel.frame.size.height)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        livesLabel.text = "Lives: 3"
        livesLabel.fontSize = 80
        livesLabel.fontColor = SKColor.white
        livesLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        livesLabel.position = CGPoint(x: self.size.width * 0.85, y: self.size.height + livesLabel.frame.size.height)
        livesLabel.zPosition = 100
        self.addChild(livesLabel)
        
        //Makes the effect of ship flying into view from underneath the screen
        let moveOnToScreenAction = SKAction.moveTo(y: self.size.height * 0.9, duration: 0.3)
        scoreLabel.run(moveOnToScreenAction)
        livesLabel.run(moveOnToScreenAction)
            
        //Set up the Start button
        tapToStartLabel.text = "Tap To Begin"
        tapToStartLabel.fontSize = 150
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.zPosition = 1
        tapToStartLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        tapToStartLabel.alpha = 0
        self.addChild(tapToStartLabel)
        
        let fadeInAction = SKAction.fadeIn(withDuration: 0.3)
        tapToStartLabel.run(fadeInAction)
        
    }
    
    var lastUpdateTime: TimeInterval = 0
    var deltaFrameTime: TimeInterval = 0
    var amountToMovePerSecond: CGFloat = 600.0 //background moves 600 points down screen per second
    
    
    
    override func update(_ currentTime: TimeInterval) {
        //using update function(runs once per game frame) to move background by moving small amount quickly
        //This is finding time between last update and this update
        if lastUpdateTime == 0{
            lastUpdateTime = currentTime
        } else {
            deltaFrameTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
        }
        
        //if gameScore % 15 == 0 && gameScore > 1 {
            //amountToMovePerSecond += 150
        //}
        
        //logic for speed of moving background based on amount of time between frames
        let amountToMoveBackground = amountToMovePerSecond * CGFloat(deltaFrameTime)
        self.enumerateChildNodes(withName: "Background") {
            background, stop in
            
            if self.currentGameState == gameState.inGame{
                background.position.y -= amountToMoveBackground
            }
            
            if background.position.y < -self.size.height{
                background.position.y += self.size.height*2
            }
            
        }
        
        
        
    }
    
    func startGame(){
        
        currentGameState = gameState.inGame //change the state
        
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        let deleteAction = SKAction.removeFromParent()
        let deleteSequence = SKAction.sequence([fadeOutAction, deleteAction])
        tapToStartLabel.run(deleteSequence) //get rid of tap to start button when game begins by fading out
        
        let moveShipOntoScreenAction = SKAction.moveTo(y: self.size.height*0.2, duration: 0.5)
        let startLevelAction = SKAction.run(startNewLevel)
        let startGameSequence = SKAction.sequence([moveShipOntoScreenAction, startLevelAction])
        player.run(startGameSequence)
    }
     
    func loseALife(){
        
        livesNumber -= 1
        livesLabel.text = "Lives: \(livesNumber)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
        
        if livesNumber == 0{
            runGameOver()
        }
    }
    
    func gainALife() {
        if livesNumber < 5 {
            livesNumber += 1
        }
        livesLabel.text = "Lives: \(livesNumber)"
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([gainLifeSound, scaleUp, scaleDown])
        livesLabel.run(scaleSequence)
    }
    
    func addScore(){
        
        gameScore += 1
        scoreLabel.text = "Score: \(gameScore)" //this prints the value of gamescore that is changing
        
        //Levels change once you reach these scores (currently 4 levels)
        if gameScore == 10 || gameScore == 25 || gameScore == 50 || gameScore == 75 {
            startNewLevel()
        }
    }
    
    func runGameOver() {
        
        currentGameState = gameState.afterGame
        
        self.removeAllActions()//this only gets rid of player ship
        
        //Makes a list of all objects w/ reference name "bullet" and stops them
        self.enumerateChildNodes(withName: "Bullet") {
            bullet, stop in
            bullet.removeAllActions()
        }
        
        self.enumerateChildNodes(withName: "Enemy") {
            enemy, stop in
            enemy.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSequence)
    }
    
    func changeScene() {
        
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode//make sure size is the same
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: myTransition)
    }
    
    
    //contact logic
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        //This value based on physics category # assigned at start
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        } else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy{
            //player hits enemy
            
            if body1.node != nil {
            spawnExplosian(spawnPosition: body1.node!.position)
            }
            
            if body2.node != nil {
            spawnExplosian(spawnPosition: body2.node!.position)
            }
            
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            runGameOver()
        }
        
        
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy && (body2.node?.position.y)! < self.size.height{
            //bullet has hit enemy
            
            addScore()
            
            if body2.node != nil {
            spawnExplosian(spawnPosition: body2.node!.position)
            }
            
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.EnemyBullet{
            //Enemy Bullet hits player
            
            //if body1.node != nil {
                //spawnExplosian(spawnPosition: body1.node!.position)
            //}
            //Only have missile explode and lose a life rather than instant Game Over
            if body2.node != nil {
                spawnExplosian(spawnPosition: body2.node!.position)
            }
            
            //body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            //runGameOver()
            loseALife()
        }
        
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.EnemyBullet{
            //Enemy Bullet hits Player Bullet
            
            if body1.node != nil {
                spawnExplosian(spawnPosition: body1.node!.position)
            }
            
            if body2.node != nil {
                spawnExplosian(spawnPosition: body2.node!.position)
            }
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Life{
            //Player hits Extra Life
            
            body2.node?.removeFromParent()
            gainALife()
            
        }
    }
    
    
    func spawnExplosian(spawnPosition: CGPoint){
        
        let explosian = SKSpriteNode(imageNamed: "explosion")
        explosian.position = spawnPosition
        explosian.zPosition = 3
        self.addChild(explosian)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosianSequence = SKAction.sequence([explosionSound, scaleIn, fadeOut, delete])
        
        explosian.run(explosianSequence)
        
    }
    
    func startNewLevel(){
        
        levelNumber += 1
        
        let newLevelBanner = SKLabelNode(fontNamed: "street cred")
        newLevelBanner.text = "Level:  \(levelNumber)"
        newLevelBanner.fontSize = 170
        newLevelBanner.fontColor = SKColor.white
        newLevelBanner.position = CGPoint(x: self.size.width*0.5, y: self.size.height*0.5)
        newLevelBanner.zPosition = 3
        self.addChild(newLevelBanner)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.7)
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let delete = SKAction.removeFromParent()
        let newLevelSequence = SKAction.sequence([scaleIn, fadeOut, delete])
        newLevelBanner.run(newLevelSequence)
        
        if self.action(forKey: "spawningEnemies") != nil{
            self.removeAction(forKey: "spawningEnemies")
        }
        
        if self.action(forKey: "spawningLives") != nil{
            self.removeAction(forKey: "spawningLives")
        }
        
        
        var levelDuration = TimeInterval()
        switch levelNumber {
        case 1: levelDuration = 1.6
        case 2: levelDuration = 1.3
        case 3: levelDuration = 1.0
        case 4: levelDuration = 0.8
        case 5: levelDuration = 0.6
        default:
            levelDuration = 0.6
            print("Cannot find level info")
        }
        
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "spawningEnemies")
        
        var timeBetweenLives = TimeInterval()
        switch levelNumber {
        case 1: timeBetweenLives = 8
        case 2: timeBetweenLives = 9
        case 3: timeBetweenLives = 10
        case 4: timeBetweenLives = 11
        case 5: timeBetweenLives = 12
        default:
            timeBetweenLives = 12
            print("Cannot find level info")
        }
        
        let spawnLife = SKAction.run(spawnExtraLife)
        let waitToSpawn2 = SKAction.wait(forDuration: timeBetweenLives)
        let spawnSequence2 = SKAction.sequence([waitToSpawn2, spawnLife])
        let spawnForever2 = SKAction.repeatForever(spawnSequence2)
        self.run(spawnForever2, withKey: "spawningLives")
    }
    
    
    
    func fireBullet() {
        
        let bullet = SKSpriteNode(imageNamed: "bullet2")
        bullet.name = "Bullet"
        bullet.setScale(1.8)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 1)
        let deleteBullet = SKAction.removeFromParent()
        let bulletSequence = SKAction.sequence([bulletSound ,moveBullet, deleteBullet])
        bullet.run(bulletSequence)
        
    }
    
    func spawnExtraLife() {
        
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        //let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXStart, y: -self.size.height * 0.2)
        
        let life = SKSpriteNode(imageNamed: "life")
        life.name = "Life"
        life.setScale(0.09)
        life.position = startPoint
        life.zPosition = 3
        life.physicsBody = SKPhysicsBody(rectangleOf: life.size)
        life.physicsBody!.affectedByGravity = false
        life.physicsBody!.categoryBitMask = PhysicsCategories.Life
        life.physicsBody!.collisionBitMask = PhysicsCategories.None
        life.physicsBody!.contactTestBitMask = PhysicsCategories.Player
        self.addChild(life)
        
        let moveLife = SKAction.move(to: endPoint, duration: 1.5)
        let deleteLife = SKAction.removeFromParent()
        let lifeSequence = SKAction.sequence([moveLife, deleteLife])
        
        if currentGameState == gameState.inGame{
            life.run(lifeSequence)
        }
    }
    
    func spawnEnemy() {
        
        let randomXStart = random(min: gameArea.minX, max: gameArea.maxX)
        let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.name = "Enemy"
        enemy.setScale(1)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.7)
        let deleteEnemy = SKAction.removeFromParent()
        let loseALifeAction = SKAction.run(loseALife)
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, loseALifeAction])
        
        
        
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
        
        if currentGameState == gameState.inGame{
            enemy.run(enemySequence)
            //for i in 0...levelNumber{
            if levelNumber > 1{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let enemyBullet = SKSpriteNode(imageNamed: "enemyBullet")
                    enemyBullet.name = "EnemyBullet"
                    enemyBullet.setScale(0.20)
                    enemyBullet.position = enemy.position
                    enemyBullet.zPosition = 1
                    enemyBullet.zRotation = amountToRotate
                    enemyBullet.physicsBody = SKPhysicsBody(rectangleOf:  enemyBullet.size)
                    enemyBullet.physicsBody!.affectedByGravity = false
                    enemyBullet.physicsBody!.categoryBitMask = PhysicsCategories.EnemyBullet
                    enemyBullet.physicsBody!.collisionBitMask = PhysicsCategories.None
                enemyBullet.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
                    self.addChild(enemyBullet)
                    
                let moveBullet = SKAction.move(to: endPoint, duration: 0.65)
                    let deleteBullet = SKAction.removeFromParent()
                    let enemyBulletSequence = SKAction.sequence([moveBullet, deleteBullet])
                    enemyBullet.run(enemyBulletSequence)
                }
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentGameState == gameState.preGame{
            startGame()
        } else if currentGameState == gameState.inGame{
            fireBullet()
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            //movement based on how far user drags finger on screen, only active during an active game
            if currentGameState == gameState.inGame{
                player.position.x += amountDragged
            }
            
            //Logic for setting the sides of screen as barriers
            if player.position.x > gameArea.maxX - player.size.width/2{
                player.position.x = gameArea.maxX - player.size.width/2
            }
            
            if player.position.x < gameArea.minX + player.size.width/2{
                player.position.x = gameArea.minX + player.size.width/2
            }
        }
    }
    
}
