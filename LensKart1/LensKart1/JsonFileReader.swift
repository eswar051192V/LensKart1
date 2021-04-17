//
//  JsonFileReader.swift
//  LensKart1
//
//  Created by Sindhu Priya on 17/04/21.
//

import Foundation

protocol FileReader {
    func read<T>(type: T) -> T?
}

class JsonFileReader: FileReader {

    var fileName: String
    var type: String
    
    init(fileName: String, type: String) {
        self.fileName = fileName
        self.type = type
    }
    
    func read<T>(type: T) -> T? {
        if let path = Bundle.main.path(forResource: self.fileName, ofType: self.type) {
            do {
                  let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                  let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                  if let jsonResult = jsonResult as? T {
                    return jsonResult
                  }
              } catch {
                   // handle error
              }
        }
        return nil
    }
    
}

struct JsonFiles {
    static let movies = "movies"
}
