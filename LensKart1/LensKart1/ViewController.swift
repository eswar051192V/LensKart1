//
//  ViewController.swift
//  LensKart1
//
//  Created by Sindhu Priya on 17/04/21.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var tableView: UITableView? {
        didSet {
            self.tableView?.dataSource = self
            self.tableView?.delegate = self
        }
    }
    
    var model: MainViewModel = ViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.estimatedRowHeight = 250 // match your tallest cell
        tableView?.rowHeight = UITableView.automaticDimension
        self.model.set(delegate: self)
        // Do any additional setup after loading the view.
    }


}

extension ViewController: UITableViewDataSource, UITableViewDelegate, MainViewModelDelegate, MainCellUpdateDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.model.numberOfSection()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.number(ofRowsFor: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PosterCell = tableView.dequeueReusableCell(withIdentifier: "Poster") as! PosterCell
        cell.indexPath = indexPath
        cell.delegate = self
        cell.setViewModel(viewModel: self.model.data(ofRow: indexPath.row, ofSection: indexPath.section))
        
        return cell
    }
    
    func updateUserInterface() {
        self.tableView?.reloadData()
    }
    
    func updateAtIndexPath(indexPath: IndexPath?) {
        
    }
}

protocol MainCellUpdateDelegate: class {
    func updateAtIndexPath(indexPath: IndexPath?)
}

protocol MainViewModelDelegate: class {
    func updateUserInterface()
}

protocol MainViewModel {
    func set(delegate: MainViewModelDelegate?)
    func numberOfSection() -> Int
    func number(ofRowsFor section: Int) -> Int
    func data<T>(ofRow row: Int, ofSection section: Int) -> T?
}

class ViewModel: MainViewModel {
    weak var delegate: MainViewModelDelegate?
    var cellViewModel: [CellViewModel] = [CellViewModel]()
    
    func set(delegate: MainViewModelDelegate?) {
        self.delegate = delegate
        let data: [[String: Any]] = JsonFileReader(fileName: JsonFiles.movies, type: "json").read(type: [[String : Any]]()) ?? [[String : Any]]()
        let models = data.map { (json) -> CellViewModel in
            return PosterCellViewModel(model: CellModel(dictionary: json))
        }
        self.cellViewModel = models
        self.updateUserInterface()
    }
    
    func updateUserInterface() {
        DispatchQueue.main.async {
            self.delegate?.updateUserInterface()
        }
    }
    
    func numberOfSection() -> Int {
        return 1
    }
    
    func number(ofRowsFor section: Int) -> Int {
        return self.cellViewModel.count
    }
    
    func data<T>(ofRow row: Int, ofSection section: Int) -> T? {
        return self.cellViewModel[row] as? T
    }
}

struct CellModel {
    var adult: Bool = false
    var backdropPath: String = ""
    var genreIds: [Int] = [Int]()
    var id: Int = 0
    var originalLanguage: String = ""
    var originalTitle: String = ""
    var overview: String = ""
    var popularity: Double = 0.0
    var posterPath: String = ""
    var release_date: String = ""
    var title: String = ""
    var video: Bool = false
    var voteAverage: Double = 0.0
    var voteCount: Int = 0
    
    init(dictionary: [String: Any]) {
        dictionary.forEach { (arg) in
            switch arg.key {
            case "adult":
                self.adult = arg.value as? Bool ?? false
            case "backdrop_path":
                self.backdropPath = arg.value as? String ?? ""
            case "genre_ids":
                self.genreIds = arg.value as? [Int] ?? [Int]()
            case "id":
                self.id = arg.value as? Int ?? 0
            case "original_language":
                self.originalLanguage = arg.value as? String ?? ""
            case "overview":
                self.overview = arg.value as? String ?? ""
            case "original_title":
                self.originalTitle = arg.value as? String ?? ""
            case "popularity":
                self.popularity = arg.value as? Double ?? 0.0
            case "poster_path":
                self.posterPath = arg.value as? String ?? ""
            case "release_date":
                self.release_date = arg.value as? String ?? ""
            case "title":
                self.title = arg.value as? String ?? ""
            case "video":
                self.video = arg.value as? Bool ?? false
            case "vote_average":
                self.voteAverage = arg.value as? Double ?? 0.0
            case "vote_count":
                self.voteCount = arg.value as? Int ?? 0
            default:
                break
            }
        }
    }
}

protocol CellViewModel {
    var title: String {get}
    var image: UIImage? {get set}
    func set(delegate: MainViewModelDelegate?)
    func loadImage()
}

class PosterCellViewModel: CellViewModel, MainViewModelDelegate {
    weak var delegate: MainViewModelDelegate?
    var image: UIImage?
    var title: String {
        return self.model.title
    }
    var model: CellModel
    init(model: CellModel) {
        self.model = model
    }
    
    func set(delegate: MainViewModelDelegate?) {
        self.delegate = delegate
        self.loadImage()
    }
    
    func updateUserInterface() {
        DispatchQueue.main.async {
            self.delegate?.updateUserInterface()
        }
        
    }
    
    func loadImage() {
        let im = ImageApiCaller(cellModel: model)
        im.call { [weak self] (image: UIImage?, error) in
            self?.image = image
            self?.updateUserInterface()
        }
    }
}

class PosterCell: UITableViewCell, MainViewModelDelegate {
    @IBOutlet var title: UILabel?
    @IBOutlet var poster: UIImageView?
    var indexPath: IndexPath?
    weak var delegate: MainCellUpdateDelegate?
    
    var viewModel: CellViewModel?
    func setViewModel(viewModel: CellViewModel?) {
        self.viewModel = viewModel
        self.viewModel?.set(delegate: self)
    }
    
    
    func updateUserInterface() {
        self.poster?.image = self.viewModel?.image
        self.title?.text = self.viewModel?.title
        self.delegate?.updateAtIndexPath(indexPath: indexPath)
    }
}
