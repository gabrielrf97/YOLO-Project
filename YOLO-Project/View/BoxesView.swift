//
//  BoxesView.swift
//  YOLO-Project
//
//  Created by Gabriel on 26/10/19.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit
import Vision

typealias BoudingBox = (box: UIView, title: UILabel)

class BoxesView: UIView {
    
    var colors = [String: UIColor]()

    var predictions: [VNRecognizedObjectObservation]? {
        didSet {
            removeExistingBoudingBoxes()
            self.predictions?.forEach({drawNewBoundingBoxes(prediction: $0)})
        }
    }
    
    func removeExistingBoudingBoxes() {
        subviews.forEach({$0.removeFromSuperview()})
    }
    
    func getColor(for identifier: String) -> UIColor {
        if let color = colors[identifier] {
            return color
        } else {
            let newColor = UIColor.random()
            colors[identifier] = newColor
            return newColor
        }
    }
    
    func drawNewBoundingBoxes(prediction: VNRecognizedObjectObservation) {
        
        let identifier = prediction.labels.first?.identifier ?? "N/A"
        
        let color = getColor(for: identifier)
        
        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let bgRect = prediction.boundingBox.applying(transform).applying(scale)
        
        let box = UIView(frame: bgRect)
        box.layer.borderColor = color.cgColor
        box.layer.borderWidth = 4
        box.backgroundColor = UIColor.clear
        addSubview(box)
        
        let title = UILabel()
        title.text = identifier
        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.white
        title.backgroundColor = color
        title.sizeToFit()
        title.frame = CGRect(x: bgRect.origin.x, y: bgRect.origin.y - title.frame.height,
                             width: title.frame.width, height: title.frame.height)
        addSubview(title)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}
