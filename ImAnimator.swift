//
//  ImAnimator.swift
//  PodCleaner
//
//  Created by Alex Raccuglia on 27/06/17.
//  Copyright © 2017 Alex Raccuglia. All rights reserved.
//

import Foundation

#if os(OSX)
import Cocoa
import TimeLibs
#else
import UIKit
#endif



#if os(OSX)
public typealias IAImageView = NSImageView
public typealias IAView = NSView
public typealias IARect = NSRect
#else
public typealias IAImageView = UIImageView
public typealias IAView = UIView
public typealias IARect = CGRect
#endif


public class ImAnim {
    
    var imageView :  IAImageView
    
    var imageIds =          [String] ()
    var currentId =         -1
    var updateInterval :    Double
    var loop :              Bool = true
    var timer :             Timer? = nil
    
    var bundle :            Bundle? = nil
    var folderPath :        String = ""
    
    var imageType =         "png"
    
    public init (_ imageView :     IAImageView,
                 updateInterval :  Double = 0,
                 fps :             Int = 30,
                 loop :            Bool = true,
                 bundle :          Bundle? = nil,
                 folderPath :      String = "",
                 imageType :       String = "png") {
        
        self.updateInterval = updateInterval
        if updateInterval == 0 {
            self.updateInterval = 1.0 / Double (fps)
        }
        self.imageView = imageView
        self.loop = loop
        self.bundle = bundle
        self.folderPath = folderPath
    }
    
    
    
    public init (_ imageView :  IAImageView,
                 idPrefix :     String) {
        
        self.updateInterval = 1.0 / 30
        self.imageView = imageView
        self.loop = true
        self.bundle = nil
        self.folderPath = ""
        autoAddIds (idPrefix)
    }
    
    
    public func addId (_ id : String) {
        imageIds.append (id)
    }
    
    
    
    public func addBatchIds (_ prefixString :  String,
                             start :           Int = 0,
                             end :             Int,
                             padding :         Int = 5) {
        
        for i in start...end {
            let name = "\(prefixString)\(strUt_padN (n: i, padN: padding))"
            self.addId (name)
        }
    }
    
    
    public func autoAddIds (_ prefixString :  String,
                            start :           Int = 0,
                            padding :         Int = 5) {
        
//        print ("ImAnim.autoAddIds (\(prefixString)")
        
        var i = start
        var name = "\(prefixString)\(strUt_padN (n: i, padN: padding))"
        var image = ImageCache.getImage (name: name)
        while image != nil {
            self.addId (name)
            i += 1
            name = "\(prefixString)\(strUt_padN (n: i, padN: padding))"
            image = ImageCache.getImage (name: name)
        }
        
//        print ("COUNT: \(self.imageIds.count)")
    }
    
    
    public func removeAllIds () {
        
//        print ("removeAllIds")
        
        imageIds = [String] ()
        currentId = -1
    }
    
    
    
    @objc func updateImage () {
        
//        print ("COUNT: \(self.imageIds.count)")
        
        DispatchQueue.global (qos: .userInitiated).async {
            self.currentId += 1
          
            if self.currentId == self.imageIds.count {
                if self.loop {
                    self.currentId = 0
                } else {
                    self.stop ()
                    return
                }
            }
  
//            print ("updateImage \(self.currentId)")

            let nextId = self.imageIds [self.currentId]
            let image = self.folderPath == "" ? ImageCache.getImage (name: nextId) : ImageCache.getImage (path: self.folderPath + nextId + "." + self.imageType)!
            
            #if os(OSX)
            
            ih_setImage (self.imageView, image)
            
            #else
            
            DispatchQueue.main.async {
                self.imageView.image = image
            }
            
            #endif
            
            if !self.loop && (self.currentId == self.imageIds.count) {
                self.stop ()
            }
        }
        
    }
    
    
    
    public func start () {
        timer = TimerHelper.newLoop (timeInterval: updateInterval,
                                     self: self,
                                     selector: #selector (updateImage))
    }
    
    
    
    public func stop () {
        timer?.invalidate ()
        timer = nil
    }
    
    
}


#if os(OSX)

public class MultiIAnim {
    
    var imList =    [ImAnim] ()
    
    public init (imageView :    NSImageView,
                 ids :          [String],
                 start :        Bool = false) {
        
        let imAnim = ImAnim (imageView, idPrefix: ids [0])
        imList.append (imAnim)
        for i in 1 ..< ids.count {
            let newIV = ih_cloneImageView (imageView)
            imList.append (ImAnim (newIV, idPrefix: ids [i]))
        }
        if start {
            self.start ()
        }
    }
    
    public func start () {
        for im in imList {
            im.start ()
        }
    }
    
    public func stop () {
        for im in imList {
            im.stop ()
        }
    }
    
}



public class ImDockAnim {
    
    static var updateInterval : Double = 0.1
    static var imageIds =       [String] ()
    static var currentId =      -1
    static var currentImageId = ""
    static var timer :          Timer? = nil
    
    static var appDockTile =  NSApplication.shared.dockTile
    
    
    public static func addId (_ id : String) {
        ImDockAnim.imageIds.append (id)
    }
    
    
    public static func addBatchIds (_ prefixString :  String,
                                    start :           Int = 0,
                                    end :             Int,
                                    padding :         Int = 5) {
        
        for i in start...end {
            let name = "\(prefixString)\(strUt_padN (n: i, padN: padding))"
            ImDockAnim.addId (name)
        }
    }
    
    
    @objc static func updateImage () {
        ImDockAnim.currentId += 1
        if ImDockAnim.currentId == ImDockAnim.imageIds.count {
            ImDockAnim.currentId = 0
        }
        ImDockAnim.currentImageId = ImDockAnim.imageIds [ImDockAnim.currentId]
        appDockTile.display ()
    }
    
    
    
    public static func start () {
        
        #if os(OSX)
        let img = NSImage (named: NSImage.Name(rawValue: ImDockAnim.imageIds [0]))
        let s = img?.size
        let r = NSRect (x: 0, y: 0, width: (s?.width)!, height: (s?.height)!)
        #else
        let img = UIImage (named: UIImage.Name(rawValue: ImDockAnim.imageIds [0]))
        let s = img?.size
        let r = UIRect (x: 0, y: 0, width: (s?.width)!, height: (s?.height)!)
        
        #endif
        
        let newView = AIMIconView (frame: r)
        appDockTile.contentView = newView
        
        ImDockAnim.timer = TimerHelper.newLoop (timeInterval: updateInterval,
                                                self: self,
                                                selector: #selector (ImDockAnim.updateImage))
    }
    
    
    
    public static func stop () {
        ImDockAnim.timer?.invalidate ()
        ImDockAnim.timer = nil
        
        ImDockAnim.currentId = 0
        ImDockAnim.currentImageId = ImDockAnim.imageIds [ImDockAnim.currentId]
        appDockTile.display ()
    }
    
    
}



public class AIMIconView : NSView {
    
    public override func draw (_ dirtyRect: NSRect) {
        
        // add a background image
        
        let name = ImDockAnim.currentImageId
        let anotherImage = NSImage (named: NSImage.Name (rawValue: name))
        let s = anotherImage?.size
        let r = NSRect (x: 0, y: 0, width: (s?.width)!, height: (s?.height)!)
        let r2 = self.bounds
        anotherImage?.draw (in: r2, from: r, operation: .copy, fraction: 1)
    }
}

#endif

