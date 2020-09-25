//
//  CircleInstruction.swift
//  TuraTalalo
//
//  Created by Balazs Erdesz on 2020. 09. 25..
//

import Foundation
import CoreGraphics
import SwiftyXMLParser
import UIKit

final class CircleInstruction : RenderingInstruction {
    init(from xmlNode: XML.Element) {
        self.type = .circle

        let radiusString = xmlNode.attributes["radius"]
        let scaleRadiusString = xmlNode.attributes["scale-radius"]
        let fillString = xmlNode.attributes["fill"]
        let strokeString = xmlNode.attributes["stroke"]
        let strokeWidthString = xmlNode.attributes["stroke-width"]
        let priorityString = xmlNode.attributes["priority"]

        self.category = xmlNode.attributes["cat"]
        self.radius = radiusString != nil ? CGFloat(Double(radiusString!)!) : -1.0
        self.scaleRadius = scaleRadiusString != nil ? Bool(scaleRadiusString!)! : false
        self.fill = XMLTypeCaster.stringToCGColor(string: fillString) ?? UIColor.black.cgColor
        self.stroke = XMLTypeCaster.stringToCGColor(string: strokeString) ?? UIColor.black.cgColor
        self.strokeWidth = strokeWidthString != nil ? CGFloat(Double(strokeWidthString!)!) : 0
        self.priority = priorityString != nil ? Int32(priorityString!) : 0
    }
}
