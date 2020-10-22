//
//  InterfaceView.swift
//  PlaneDetect
//
//  Created by Nien Lam on 10/8/20.
//

import UIKit

class InterfaceView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            return nil
        }
        return hitView
    }
}
