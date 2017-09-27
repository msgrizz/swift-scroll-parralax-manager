//
//  ScrollParralaxManager.swift
//  Lit Technologies
//
//  Created by Philip Bui on 27/09/2017.
//  Copyright © 2017 Philip Bui. All rights reserved.
//

import UIKit

class ScrollParralaxManager: NSObject {
    
    let header: UIView
    let coverPhoto: UIImageView
    let coverPhotoBlurred: UIImageView?
    let headerLabel: UILabel?
    let scrollView: UIScrollView
    let photo: UIImageView?
    let navigationController: UINavigationController?
    let navigationBarHeight: CGFloat
    let headerStop: CGFloat
    var headerLabelExists: CGFloat
    let headerDistance: CGFloat
    let previousBackgroundImage: UIImage?
    let previousShadowImage: UIImage?
    let previousTranslucent: Bool?
    let previousBackgroundColor: UIColor?
    
    required init(_ headerView: UIView, _ coverPhoto: UIImageView, _ headerLabel: UILabel? = nil, _ scrollView: UIScrollView, photo: UIImageView? = nil, navigationController: UINavigationController?, labelOffset: CGFloat = 32, headerDistance: CGFloat = 30) {
        self.header = headerView
        header.clipsToBounds = true
        self.coverPhoto = coverPhoto
        self.headerLabel = headerLabel
        if let headerLabel = headerLabel {
            coverPhotoBlurred = UIImageView(frame: headerView.bounds)
            coverPhotoBlurred!.contentMode = UIViewContentMode.scaleAspectFit
            coverPhotoBlurred!.alpha = 0.0
            headerView.insertSubview(coverPhotoBlurred!, belowSubview: headerLabel)
        } else {
            coverPhotoBlurred = nil
        }
        self.scrollView = scrollView
        self.photo = photo
        self.navigationController = navigationController
        if let navigationBarHeight = navigationController?.navigationBar.frame.height {
            self.navigationBarHeight = navigationBarHeight + UIApplication.shared.statusBarFrame.height
        } else {
            navigationBarHeight = 64
        }
        headerStop = headerView.frame.height - navigationBarHeight
        headerLabelExists = headerView.frame.height + labelOffset - navigationBarHeight
        self.headerDistance = headerDistance
        previousBackgroundImage = navigationController?.navigationBar.backgroundImage(for: .default)
        previousShadowImage = navigationController?.navigationBar.shadowImage
        previousTranslucent = navigationController?.navigationBar.isTranslucent
        previousBackgroundColor = navigationController?.view.backgroundColor
        super.init()
        viewWillAppear()
        coverPhotoBlurred(coverPhoto.image)
        scrollView.delegate = self
    }
    
    func viewWillAppear() {
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController.navigationBar.shadowImage = UIImage()
        navigationController.navigationBar.isTranslucent = true
        navigationController.view.backgroundColor = UIColor.clear
    }
    
    func viewWillDisappear() {
        guard let navigationController = navigationController else {
            return
        }
        navigationController.navigationBar.setBackgroundImage(previousBackgroundImage, for: .default)
        navigationController.navigationBar.shadowImage = previousShadowImage
        navigationController.navigationBar.isTranslucent = previousTranslucent!
        navigationController.view.backgroundColor = previousBackgroundColor
    }
    
    func coverPhotoBlurred(_ image: UIImage?) {
        coverPhotoBlurred?.image = image?.blurredImage(withRadius: 10, iterations: 10, tintColor: UIColor.clear)
    }
    
    func headerLabelExists(_ labelOffset: CGFloat) {
        headerLabelExists = header.frame.height + labelOffset - navigationBarHeight
    }
}

extension ScrollParralaxManager: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        var headerTransform = CATransform3DIdentity
        var photoTransform = CATransform3DIdentity
        if offsetY < 0 { // Scrolling up above scrollView. Increase header height
            let headerScaleFactor : CGFloat = -(offsetY) / header.bounds.height
            let headerSizeVariation = ((header.bounds.height * (1.0 + headerScaleFactor)) - header.bounds.height)/2.0
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizeVariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            print(headerScaleFactor)
            header.layer.transform = headerTransform
        } else {
            // Header
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-headerStop, -offsetY), 0)
            // Label
            if let headerLabel = headerLabel {
                let labelTransform = CATransform3DMakeTranslation(0, max(-headerDistance, headerLabelExists - offsetY), 0)
                headerLabel.layer.transform = labelTransform
                // Blur
                if let coverPhotoBlurred = coverPhotoBlurred {
                    coverPhotoBlurred.alpha = min(1.0, (offsetY - headerLabelExists)/headerDistance)
                }
            }
            // Photo
            if let photo = photo {
                let photoScaleFactor = (min(headerStop, offsetY)) / photo.bounds.height / 1.4 // Slow down the animation
                let photoSizeVariation = ((photo.bounds.height * (1.0 + photoScaleFactor)) - photo.bounds.height) / 2.0
                photoTransform = CATransform3DTranslate(photoTransform, 0, photoSizeVariation, 0)
                photoTransform = CATransform3DScale(photoTransform, 1.0 - photoScaleFactor, 1.0 - photoScaleFactor, 0)
                if offsetY <= headerStop {
                    if photo.layer.zPosition < header.layer.zPosition{
                        header.layer.zPosition = 0
                    }
                } else if photo.layer.zPosition >= header.layer.zPosition{
                    header.layer.zPosition = 2
                }
            }
        }
        // Apply Transformations
        header.layer.transform = headerTransform
        photo?.layer.transform = photoTransform
    }
}
