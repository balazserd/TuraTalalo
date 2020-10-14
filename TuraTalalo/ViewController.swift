//
//  ViewController.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 20..
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapFileReader = MapFileReader(fileUrl: Bundle.main.url(forResource: "huntura",
                                                                   withExtension: "map")!)
        mapFileReader.open()

        let key = TileKey(x: 566, y: 356, z: 10, isTopLeft: true)
        let tile = mapFileReader.readTile(keyed: key, offset: 1)

        let renderTheme = RenderTheme(withFileUrl: Bundle.main.url(forResource: "Elevate_Hiking",
                                                                   withExtension: "xml")!)
        renderTheme.read()

        let mapRenderer = MapRenderer(theme: renderTheme, preferredLanguage: "en")
        let uiRenderer = UIGraphicsImageRenderer(bounds: view.bounds)

        let mapTileImage = try! mapRenderer.renderTile(keyed: key,
                                                       in: uiRenderer,
                                                       tile: tile,
                                                       layerId: renderTheme.defaultLayerName ?? nil,
                                                       queryBuffer: 256)

        mapView.image = mapTileImage
    }
}

