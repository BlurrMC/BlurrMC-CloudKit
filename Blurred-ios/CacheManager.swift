//
//  CacheManager.swift
//  Blurred-ios
//
//  Created by Martin Velev on 8/9/20.
//  Copyright © 2020 BlurrMC. All rights reserved.
//

import Foundation
import AVFoundation

class CacheManager {
    
    // MARK: Lets
    static let shared = CacheManager()
    private let fileManager = FileManager.default

    // MARK: Variables
    private lazy var mainDirectoryUrl: URL = {
        let documentsUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return documentsUrl
    }()
    
    
    // MARK: Try and clear the contents of the cache.
    func clearContents(_ url:URL) {

        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: url.path)
            let urls = contents.map { URL(string:"\(url.appendingPathComponent("\($0)"))")! }
            urls.forEach {  try? FileManager.default.removeItem(at: $0) }
        }
        catch {

            print(error)

        }

     }
    
    
    // MARK: Get File With URL
    func getFileWith(stringUrl: String, completionHandler: @escaping (Result<URL>) -> Void ) {


        let file = directoryFor(stringUrl: stringUrl)

        //return file path if already exists in cache directory
        guard !fileManager.fileExists(atPath: file.path)  else {
            completionHandler(Result.success(file))
            return
        }

        DispatchQueue.global().async {
            

            if let videoData = NSData(contentsOf: URL(string: stringUrl)!) {
                videoData.write(to: file, atomically: true)

                DispatchQueue.main.async {
                    completionHandler(Result.success(file))
                }
            } else {
                print("error code: 1957329172, url: \(stringUrl)")
            }
        }
        
        
    }

    
    // MARK: Get Directory For URl
    private func directoryFor(stringUrl: String) -> URL {

        let fileURL = URL(string: stringUrl)!.lastPathComponent

        let file = self.mainDirectoryUrl.appendingPathComponent(fileURL)

        return file
    }
}
