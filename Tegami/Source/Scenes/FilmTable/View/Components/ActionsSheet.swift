//
//  ActionsSheet.swift
//  GhibliAPP
//
//  Created by Yago Marques on 23/09/22.
//

import UIKit

final class ActionSheet: UIViewController {

    weak var delegate: ActionSheetDelegate?
    weak var overViewDelegate: OverViewDelegate?

    init(delegate: ActionSheetDelegate, overViewDelegate: OverViewDelegate? = nil) {
        self.delegate = delegate
        self.overViewDelegate = overViewDelegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("error ActionSheet")
    }

    var film: Film = .init(id: "", title: "", posterImage: Data(), runningTime: "", releaseDate: "", genre: "", bannerImage: Data(), description: "", popularity: 0.00) {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let self {
                    self.titleLabel.text = self.film.title
                    self.filmBackdropView.image = UIImage(data: self.film.bannerImage)
                }
            }
        }
    }

    var contentOfRowAt: [(title: String, image: String)] = []

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center

        return label
    }()

    private let textShape: UIView = {
        let shape = UIView(frame: .zero)
        shape.translatesAutoresizingMaskIntoConstraints = false
        shape.backgroundColor = .systemGray5
        shape.layer.opacity = 0.6
        shape.layer.cornerCurve = .circular
        shape.layer.cornerRadius = 10

        return shape
    }()

    private let filmBackdropView: UIImageView = {
        let image = UIImageView(frame: .zero)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.backgroundColor = .systemGray5

        return image
    }()

    private lazy var actionsTable: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.register(ActionSheetCell.self, forCellReuseIdentifier: "ActionSheetCell")
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .systemGray5
        table.allowsSelection = true
        table.isUserInteractionEnabled = true
        table.translatesAutoresizingMaskIntoConstraints = false
        table.showsVerticalScrollIndicator = false

        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        buildLayout()
    }

}

extension ActionSheet: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contentOfRowAt.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = actionsTable.dequeueReusableCell(withIdentifier: "ActionSheetCell", for: indexPath) as? ActionSheetCell else {
            return UITableViewCell(frame: .zero)
        }
        cell.actionData = self.contentOfRowAt[indexPath.row]

        return cell
    }
}

extension ActionSheet: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ActionSheetCell
        if
            let delegate = self.delegate,
            let label = cell.actionLabel.text
        {
            let id = self.film.id
            switch label {
            case "Adicionar na minha lista":
                delegate.addNewFilmToList(id: id)
            case "Remover da minha lista":
                delegate.removeFilmOfList(id: id)
            case "Tornar o primeiro da lista":
                delegate.turnFirstOfList(id: id)
            case "Marcar como assistido":
                delegate.markFilmAsWatched(id: id)
            default:
                print("error not expected")
            }

            self.dismiss(animated: true)

            self.overViewDelegate?.popView()

        }
    }
}

extension ActionSheet: ViewCoding {
    func setupView() {
        view.backgroundColor = .systemGray5
    }

    func setupHierarchy() {
        view.addSubview(filmBackdropView)
        view.addSubview(textShape)
        view.addSubview(titleLabel)
        view.addSubview(actionsTable)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            filmBackdropView.topAnchor.constraint(equalTo: view.topAnchor),
            filmBackdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filmBackdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filmBackdropView.heightAnchor.constraint(equalTo: filmBackdropView.widthAnchor, multiplier: 0.565),

            textShape.heightAnchor.constraint(equalTo: filmBackdropView.heightAnchor, multiplier: 0.7),
            textShape.widthAnchor.constraint(equalTo: filmBackdropView.widthAnchor, multiplier: 0.7),
            textShape.centerXAnchor.constraint(equalTo: filmBackdropView.centerXAnchor),
            textShape.centerYAnchor.constraint(equalTo: filmBackdropView.centerYAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: textShape.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: textShape.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: textShape.widthAnchor, multiplier: 0.9),

            actionsTable.topAnchor.constraint(equalTo: filmBackdropView.bottomAnchor),
            actionsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionsTable.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])

    }
}
