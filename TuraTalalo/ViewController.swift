//
//  ViewController.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 20..
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    @IBOutlet weak var mapSpriteView: SKView!

    override func viewDidLoad() {
        let mapFileReader = MapFileReader(fileUrl: Bundle.main.url(forResource: "HungarianTouristMap", withExtension: "map")!)
        mapFileReader.open()

        super.viewDidLoad()

        let scene = SKScene(size: mapSpriteView.bounds.size)
        scene.anchorPoint = CGPoint(x: 0, y: 0.5)

        var points = [
            CGPoint(x:   0, y:   0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 200, y: -50),
            CGPoint(x: 300, y:  30),
            CGPoint(x: 400, y:  20)
        ]

        let pathNode = SKShapeNode(splinePoints: &points, count: points.count)
        scene.addChild(pathNode)
        mapSpriteView.presentScene(scene)
    }


}

