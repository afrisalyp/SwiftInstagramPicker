//
//  ALImageFetchingInteractor.swift
//  ALImagePickerViewController
//
//  Created by Alex Littlejohn on 2015/06/09.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import Photos

public typealias ImageFetcherSuccess = (assets: [IGMedia]) -> ()
public typealias ImageFetcherFailure = (error: NSError) -> ()

extension PHFetchResult: SequenceType {
    public func generate() -> NSFastGenerator {
        return NSFastGenerator(self)
    }
}

public class ImageFetcher {

    private var success: ImageFetcherSuccess?
    private var failure: ImageFetcherFailure?
    
    private var authRequested = false
    private let errorDomain = "com.zero.imageFetcher"

    public init() { }
    
    public func onSuccess(success: ImageFetcherSuccess) -> Self {
        self.success = success
        return self
    }
    
    public func onFailure(failure: ImageFetcherFailure) -> Self {
        self.failure = failure
        return self
    }
    
    public func fetch(accessToken: String) -> Self {
        let request = NSMutableURLRequest(URL: NSURL(string: "https://api.instagram.com/v1/users/self/media/recent/?access_token=\(accessToken)")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if let data = data {
                let medias = self.parseMedia(data)
                dispatch_async(dispatch_get_main_queue()) {
                    self.success?(assets: medias!)
                }
            }
            else {
                self.failure?(error: NSError(domain: "error", code: 0, userInfo: nil))
            }
        })
        task.resume()
        return self
    }
    
    private func parseMedia(data: NSData) -> [IGMedia]? {
        do {
            var medias = [IGMedia]()
            let responseData = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves)
            
            if let mediasData = responseData["data"] as? [AnyObject] {
                for mediaData in mediasData {
                    if let mediaData = mediaData as? [String: AnyObject] {
                        let media: IGMedia = IGMedia()
                        if let mediaId = mediaData["id"] as? String {
                            media.id = mediaId
                        }
                        if let imagesData = mediaData["images"] as? [String: AnyObject], let mediaUrl = imagesData["standard_resolution"]?["url"] as? String {
                            media.url = mediaUrl
                        }
                        medias.append(media)
                    }
                }
            }
            return medias
        }
        catch {
            return nil
        }
    }
}
