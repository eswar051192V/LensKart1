//
//  ApiCaller.swift
//  LensKart1
//
//  Created by Sindhu Priya on 17/04/21.
//

import Foundation
import UIKit

typealias ApiCallback = (Data?, Error?) -> Void

protocol ApiCaller {
    var url: URL? {get}
    func call<T>(completion: ((T?, Error?) -> Void)?)
}

class ImageApiCaller: ApiCaller {
    let queue = DispatchQueue(label: "com.image")
    var url: URL? {
        return URL(string: self.urlString)
    }
    
    var urlString: String
    var cellModel: CellModel
    
    init(cellModel: CellModel) {
        self.cellModel = cellModel
        self.urlString = cellModel.posterPath.extendedUrlForPosterPath
    }
    
    func call<T>(completion: ((T?, Error?) -> Void)?) {
        self.queue.async {
            let name = (self.cellModel.posterPath as NSString).replacingOccurrences(of: "/", with: "")
            if let image = self.loadImage(withName: name) {
                completion?(image as? T, nil)
            }
            
            let api = GeneralApiCaller(url: self.url)
            api.call { [weak self] (data: Data?, error) in
                DispatchQueue.main.async {
                    guard let data = data, let image = UIImage(data: data) else {
                        completion?(nil, error)
                        return
                    }
                    self?.saveImage(image, name: name)
                    completion?(image as? T, nil)
                }
            }
        }
    }
    
    @discardableResult func saveImage(_ image: UIImage, name: String) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 1) else {
            return nil
        }
        do {
            let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            return nil
        }
    }

    // returns an image if there is one with the given name, otherwise returns nil
    func loadImage(withName name: String) -> UIImage? {
        let imageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
        return UIImage(contentsOfFile: imageURL.path)
    }
}

enum APiError: Error {
    case failedToLoadImage
    case missingUrl
}

class GeneralApiCaller: ApiCaller {
    var url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    func call<T>(completion: ((T?, Error?) -> Void)?) {
        guard let url = self.url else {
            completion?(nil, APiError.missingUrl)
            return
        }
        MainDownloadDataUseCase.getData(url: url) { (data, _, error) in
            completion?(data as? T, error)
        }
    }
}

struct URLSetup {
    static let baseUrl = "http://image.tmdb.org/t/p/w92"
}

extension String {
    var extendedUrlForPosterPath: String {
        return URLSetup.baseUrl + self
    }
}

public class MainDownloadDataUseCase {
    public static func getData(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
        }
    }
}
