//
//  SourceProvider.swift
//  Test1
//
//  Created by Tehila Amran on 16/06/2020.
//  Copyright © 2020 None. All rights reserved.
//

import Foundation
import UIKit



class SourceProvider: NSObject{
    
    static let sharedProvider = SourceProvider()
    var source = [String]()
    var tasksResults = [String : Int]()
    var images = [UIImage]()
 
    
    func downloadSource(url: String?, callback: @escaping ((_ done: Bool) -> ()) ) {

        if self.images.count > 0 {
            print("source already downloaded")
             callback(true)
             return
        }

        guard let destinationURL = url else {
            callback(false)
            return
        }
        guard let URL = URL(string: destinationURL) else {
            callback(false)
            return
        }

        let session = URLSession.shared
        let task =  session.dataTask(with: URL) { [weak self](data, response, error) in
            
            guard let bself = self else{
                callback(false)
                return
            }

                if error != nil {
                    print(error!.localizedDescription)
                    callback(true)
                    return
                }
                
                guard let dataObj = data else {
                    callback(false)
                    return
                    
                }

            if let json = try? JSONSerialization.jsonObject(with: dataObj, options: []) as? [AnyHashable : [String : String]]{
                    
                    print("json \n \(json)")

                        for ( key , dic) in json {

                            if let imgSourcePath = dic["image"] {
                                bself.source.append(imgSourcePath)
                                print("\(imgSourcePath) --  \(key)")
                             }
                         }
                        
                        bself.downloadImages(arrPaths: bself.source, callback: callback)
                 }
             }
            
            task.resume()
         }

        
     private  func downloadImages(arrPaths: [String]?, callback: @escaping ((_ done : Bool) -> ()))  {

        self.images.removeAll()
            guard let paths = arrPaths else {
                callback(false)
                return
            }


            let taskGroup = DispatchGroup()

            
            let session = URLSession.shared
            
            for fileUrl in paths {
                
                let url = URL(string: fileUrl)

                if url != nil {

                    taskGroup.enter()
                    
                    let task = session.downloadTask(with: url!) {[weak self] (tmpUrl, response, error) in
                        
                        if error != nil {
                            print(error!.localizedDescription)
                            taskGroup.leave()
                             return
                        }

                        //save
                        self?.storeImage(localUrl: tmpUrl)
                        taskGroup.leave()
                      }
                    task.resume()
                 }
               }


            taskGroup.notify(queue: .main) {
                // All tasks are done.
                 callback(true)
             }
          }

    private func storeImage(localUrl: URL?){

        guard let pathURL = localUrl else {
            return
        }

        guard let imageData = try? Data(contentsOf: pathURL) else {
                        return
        }
        if let image = UIImage(data: imageData){
            self.images.append(image)
         }

    }
    
    private func tasksFinished (path: String) -> Bool{
        
        self.tasksResults[path] = 1
        if self.tasksResults .count == self.source.count {
            return true
        }
        return false
 
    }
        

}
