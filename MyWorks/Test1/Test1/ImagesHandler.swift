//
//  ImagesHandler.swift
//  Test1
//
//  Created by Yoav Dror on 16/06/2020.
//  Copyright © 2020 None. All rights reserved.
//

import Foundation
import UIKit

class ImagesHandler: NSObject {

    static func blendImages(_ img: UIImage,_ imgTwo: UIImage?) -> Data? {


        let bottomImage = img
        guard let topImage = imgTwo else {
            return nil
        }


        let screenSize:CGSize = UIScreen.main.bounds.size
        let width = screenSize.width
        let height = screenSize.height

        let imgView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height:height))
        let imgView2 = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))

        // - Set Content mode to what you desire
        imgView.contentMode = .scaleAspectFill
        imgView2.contentMode = .scaleAspectFill
        imgView2.alpha = 0.3

        // - Set Images
        imgView.image = bottomImage
        imgView2.image = topImage

        // - Create UIView
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        contentView.addSubview(imgView)
        contentView.addSubview(imgView2)

        // - Set Size
        let size = CGSize(width: width, height: height)

        // - Where the magic happens
        UIGraphicsBeginImageContextWithOptions(size, true, 0)

        contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: true)

        guard let i = UIGraphicsGetImageFromCurrentImageContext(),
            let data = i.jpegData(compressionQuality: 1.0)
            else {return nil}

        UIGraphicsEndImageContext()

        return data
    }
    

}
