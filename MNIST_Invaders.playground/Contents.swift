//: A UIKit based Playground for presenting user interface

//Thanks for checking out my game, MNIST Invaders! It's my take on the popular Space Invaders game that uses the MNIST model with the help of Apple's CoreML framework to attack the enemies. To play, run the playground and draw the number of enemies in the current wave to kill them. The game ends when the "invaders" reach the bottom of the screen. Run the program again to play again after losing. NOTE: Draw the figures as large as possible (take up the whole black screen) for the best accuracy with the MNIST mlmodel.

import UIKit
import PlaygroundSupport
import SpriteKit
import AVFoundation

let fontURL = Bundle.main.url(forResource: "spaceinvaders", withExtension: "TTF")
CTFontManagerRegisterFontsForURL(fontURL! as CFURL, CTFontManagerScope.process, nil)

var numEnemies = UInt32(3)
var prediction = 0
var waveNum = 1
var scoreValue = 0;
var gameOver = false

var player: AVAudioPlayer?

let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 380, height: 600))
sceneView.allowsTransparency = true

fileprivate var scoreView: UILabel = {
    let score = UILabel(frame: CGRect(x: 0, y: 160, width: 380, height: 51))
    score.center = CGPoint(x: 60, y: 80)
    score.textAlignment = .center
    score.text = "SCORE: " + String(scoreValue)
    score.textColor = UIColor.white
    score.font = UIFont(name:"04b03", size: 16.0)
    return score
}()

fileprivate var waveView: UILabel = {
    let waveCount = UILabel(frame: CGRect(x: 0, y: 160, width: 380, height: 51))
    waveCount.center = CGPoint(x: 320, y: 80)
    waveCount.textAlignment = .center
    waveCount.text = "WAVE: " + String(waveNum)
    waveCount.textColor = UIColor.white
    waveCount.font = UIFont(name:"04b03", size: 16.0)
    return waveCount
}()

func playCorrectSound() {
    guard let url = Bundle.main.url(forResource: "laser", withExtension: "wav") else { return }
    
    do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
        
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        
        guard let player = player else { return }
        
        player.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}

func playLoseSound() {
    guard let url = Bundle.main.url(forResource: "death_sound", withExtension: "wav") else { return }
    
    do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
        
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        
        guard let player = player else { return }
        
        player.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}

class MyViewController : UIViewController {
    
    fileprivate lazy var drawView: DrawView = {
        let view = DrawView()
        //view.delegate = self as! DrawViewDelegate
        view.backgroundColor = .black
        //view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    override func loadView() {
        let title = UILabel(frame: CGRect(x: 0, y: 80, width: 380, height: 51))
        title.center = CGPoint(x: 190, y: 20)
        title.textAlignment = .center
        title.backgroundColor = .white
        title.text = "MNIST INVADERS 👾"
        title.textColor = UIColor.black
        title.font = UIFont(name:"04b03", size: 32.0)
        
        let predictButton = UIButton()
        predictButton.frame = CGRect(x: 0, y: 550, width: 200, height: 100)
        predictButton.setTitle("PREDICT", for: .normal)
        predictButton.titleLabel?.font = UIFont(name:"04b03", size: 32.0)
        predictButton.setTitleColor(UIColor.white, for: .normal)
        predictButton.backgroundColor = UIColor.clear
        predictButton.addTarget(self, action: #selector(predictMNIST), for: .touchUpInside)
        predictButton.titleLabel?.textAlignment = .center
        
        let clearButton = UIButton()
        clearButton.frame = CGRect(x: 180, y: 550, width: 200, height: 100)
        clearButton.setTitle("ClEAR", for: .normal)
        clearButton.setTitleColor(UIColor.white, for: .normal)
        clearButton.titleLabel?.font = UIFont(name:"04b03", size: 32.0)
        clearButton.backgroundColor = UIColor.clear
        clearButton.addTarget(self, action: #selector(clearBoard), for: .touchUpInside)
        clearButton.titleLabel?.textAlignment = .center
        
        let view = self.drawView
        view.backgroundColor = .black
    
        if let scene = GameScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            scene.backgroundColor = .clear
            // Present the scene
            sceneView.presentScene(scene)
        }
        
        //view.addSubview(label)
        view.addSubview(sceneView)
        view.addSubview(predictButton)
        view.addSubview(clearButton)
        view.addSubview(title)
        view.addSubview(scoreView)
        view.addSubview(waveView)
        self.view = view
    }
    
    @objc func predictMNIST(){
        //print("predicting")
        let size = CGSize(width: 28, height: 28)
        guard let img = self.drawView.getImage() else {
            return
        }
        guard let image = img.resize(to: size)?.pixelBuffer() else {
            fatalError()
        }
        
        guard let result = try? MNIST().prediction(image: image) else {
            fatalError()
        }
        //print(numEnemies)
        if(result.classLabel == UInt64(numEnemies)){
            //print("killed")
            prediction = Int(result.classLabel)
            playCorrectSound()
            
            //update values
            scoreValue += (Int(numEnemies) * 10)
            scoreView.text = "SCORE: " + String(scoreValue)
            waveNum += 1
            waveView.text = "WAVE: " + String(waveNum)
        }
        //print(result.classLabel)
        clearBoard()
    }
    
    @objc func clearBoard(){
        //print("canvas cleared")
        self.drawView.clear()
    }
    
}

class GameScene: SKScene {
    
    let gameScore = 0
    var timer: Timer!
    
     override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx:0, dy:-0.13)
        if(!gameOver){
            runWaves()
        }
    }
    
    @objc func generateWave(){
        let screenWidth = (self.view?.frame.size.width)! //0 is middle
        numEnemies = arc4random_uniform(9) + 1
        //generate random num of waves
        for num in 1...numEnemies{
            let shape = SKSpriteNode(imageNamed:"space_invader")
            shape.xScale = 0.08
            shape.yScale = 0.08
            let xPos = screenWidth * -0.6 + CGFloat(num) * (screenWidth / CGFloat(numEnemies))
            shape.position = CGPoint (x: xPos,y:0)
            shape.physicsBody?.velocity = CGVector(dx: 0, dy: -1)
            shape.physicsBody = SKPhysicsBody(circleOfRadius: shape.frame.size.width/2)
            self.addChild(shape)
        }
    }
    
    func runWaves(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        if(!gameOver){
            timer = Timer.scheduledTimer(timeInterval: 12, target: self, selector: #selector(self.generateWave), userInfo: nil, repeats: true)
        }
    }
    
    func death(){
        self.removeAllChildren()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(!gameOver){
            if(prediction == numEnemies){
                death()
            }
            
            enumerateChildNodes(withName: "//*", using:
                { (node, stop) -> Void in
                    if(node.position.y < -400){
                        
                        //reset if enemy hits base
                        playLoseSound()
                        print("GAME OVER") //replace with label
                        gameOver = true
                        //scoreValue = 0
                        //waveNum = 0
                        //scoreView.text = "SCORE: " + String(scoreValue)
                        //waveView.text = "WAVE: " + String(waveNum)
                    }
            })
        }
    }
}

// Present the view controller in the Live View window
let myViewController = MyViewController()
PlaygroundPage.current.liveView = myViewController
PlaygroundPage.current.needsIndefiniteExecution = true
