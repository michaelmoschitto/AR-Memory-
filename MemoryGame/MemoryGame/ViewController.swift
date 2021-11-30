//
//  ViewController.swift
//  MemoryGame
//
//  Created by Isabella Dossola on 11/18/21.
//


//bella 2nd change

import UIKit
import RealityKit
import Combine
class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    var cards: [Entity] = []
    var flipped: [Entity] = []
    var anchor: AnchorEntity!
    var scoreEntity: ModelEntity!
    var score: Int = 0
    
    func createText(){
        
        let scoreFont = UIFont(name: "HelveticaNeue-Bold", size: 2)!
        let mesh = MeshResource.generateText(
            "Score: \(self.score / 2)",
                    extrusionDepth: 0.1,
                    font: scoreFont,
                    containerFrame: .zero,
                    alignment: .left,
                    lineBreakMode: .byTruncatingTail)
             
        
        let fontColor: UIColor = UIColor(red: 24, green: 154, blue: 180, alpha: 1)
        let material = SimpleMaterial(color: .cyan, isMetallic: false)
        self.scoreEntity = ModelEntity(mesh: mesh, materials: [material])
        self.scoreEntity.scale = SIMD3<Float>(0.03, 0.03, 0.2)
        self.scoreEntity.position = [-0.1, 0.3, 0]
        
        self.anchor.addChild(self.scoreEntity)
    }
    
    
    
    func showEndGanme(){
        performSegue(withIdentifier: "segueToEndGame", sender: nil)
    }
    
    func updateScore(){
        print("update score")
        self.score += 1
        
        print(self.score)
      
        self.anchor.removeChild(self.scoreEntity)
        self.createText()
        
        if (self.score / 2) >= 8{
            showEndGanme()
        }
    }
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the "Box" scene from the "Experience" Reality File
        //        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        //        arView.scene.anchors.append(boxAnchor)
        
        self.anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        arView.scene.addAnchor(anchor)
        
        
        
        for _ in 1...16 {
            let box = MeshResource.generateBox(width: 0.04, height: 0.002, depth: 0.04)
            
            let metalMaterial = SimpleMaterial(color: .gray, isMetallic: true)
            
            let model = ModelEntity(mesh: box, materials: [metalMaterial])
            model.generateCollisionShapes(recursive: true)
            
            cards.append(model)
        }
        
        for (index, card) in cards.enumerated(){
            let x  = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            
            card.position = [x*0.1, 0, z*0.1]
            anchor.addChild(card)
        }
        
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox(size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        
        occlusionBox.position.y = -boxSize / 2
        anchor.addChild(occlusionBox)
        
        
        var cancellable: AnyCancellable?  = nil
        cancellable = ModelEntity.loadModelAsync(named: "01")
            .append(ModelEntity.loadModelAsync(named: "02"))
            .append(ModelEntity.loadModelAsync(named: "03"))
            .append(ModelEntity.loadModelAsync(named: "04"))
            .append(ModelEntity.loadModelAsync(named: "05"))
            .append(ModelEntity.loadModelAsync(named: "06"))
            .append(ModelEntity.loadModelAsync(named: "07"))
            .append(ModelEntity.loadModelAsync(named: "08"))
            .collect()
            .sink(receiveCompletion: {error in
                print("Error: \(error) ")
                cancellable?.cancel()
                
            }, receiveValue: { entities in
                var objects: [ModelEntity] = []
                
                let names: [String] = ["01", "02", "03", "04", "05", "06", "07", "08"]
                
                for (i, entity) in entities.enumerated(){
                    entity.setScale(SIMD3<Float>(0.002, 0.002, 0.002), relativeTo: self.anchor)
                    entity.generateCollisionShapes(recursive: true)
                    entity.name = names[i]
                    
                    for _ in 1...2{
                        objects.append(entity.clone(recursive: true))
                    }
                }
                
                
//                objects.shuffle()
                
                for (index, object) in objects.enumerated() {
                    self.cards[index].addChild(object)
                    self.cards[index].name = "card \(object.name)"
                    
                    self.cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                }
                
                cancellable?.cancel()
                
            })
        
        //
        
        //
        
        //
        //
        //                }
        //
        //                objects.shuffle()
        //
        //
        //            })
        
        
        self.createText()
    }
    
    
    func flipCard(card: Entity){
        if card.transform.rotation.angle == .pi {
            var flipDownTransform = card.transform
            
            flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            
            card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
        }else{
            var flipUpTransform = card.transform
            flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            
            card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
        }
    }
    
    
    func findMatches() -> [String] {
        let dups = Dictionary(grouping: self.flipped, by: {$0.name}).filter { $1.count > 1 }.keys
        
        print(dups)
        
        return Array(dups.map{$0})
    }
    
    
    @IBAction func onTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        
        
        
        if let hitResult = arView?.entity(at: tapLocation) {
            print("hit result")
            print(String(hitResult.id))
            print(hitResult.name)
            
            if hitResult.name.contains("card"){
                flipped.append(hitResult)
            }
            
        }
        
        if let card = arView.entity(at: tapLocation){
            if card.transform.rotation.angle == .pi {
                self.flipCard(card: card)
            }
            
            
            if self.flipped.count >= 2{
                //        this is magic...
                let seconds = 2.0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    // Put your code which should be executed with a delay here
                    print("Testing delay!!")
                    
                    
                    let dupNames: [String] = self.findMatches()
                    
                    for card in self.flipped{
                        self.flipCard(card: card)
                        if dupNames.contains(card.name){
                            print("Found Duplicate!!")
                            self.updateScore()
                            self.anchor.removeChild(card)
                        }
                    }
                    
                    self.flipped = []
                }
            }
        }
    }
    
    
}



