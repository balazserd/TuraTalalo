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
        super.viewDidLoad()

        let mapFileReader = MapFileReader(fileUrl: Bundle.main.url(forResource: "huntura",
                                                                   withExtension: "map")!)
        mapFileReader.open()

        let key = TileKey(x: 1, y: 0, z: 13, isTopLeft: false)
        let tile = mapFileReader.readTile(keyed: key, offset: 1)

        let renderTheme = RenderTheme(withFileUrl: Bundle.main.url(forResource: "Elevate_Hiking",
                                                                   withExtension: "xml")!)
        renderTheme.read()

        let mapRenderer = MapRenderer(theme: renderTheme, preferredLanguage: "en")
        let uiRenderer = UIGraphicsImageRenderer(bounds: view.bounds)

        try! mapRenderer.renderTile(keyed: key,
                                    in: uiRenderer,
                                    tile: tile,
                                    layerId: renderTheme.defaultLayerName ?? "",
                                    queryBuffer: 256)

//        let scene = SKScene(size: mapSpriteView.bounds.size)
//        scene.anchorPoint = CGPoint(x: 0, y: 0.5)
//
//        var points = [
//            CGPoint(x:   0, y:   0),
//            CGPoint(x: 100, y: 100),
//            CGPoint(x: 200, y: -50),
//            CGPoint(x: 300, y:  30),
//            CGPoint(x: 400, y:  20)
//        ]
//
//        let pathNode = SKShapeNode(splinePoints: &points, count: points.count)
//        scene.addChild(pathNode)
//        mapSpriteView.presentScene(scene)
    }


}

