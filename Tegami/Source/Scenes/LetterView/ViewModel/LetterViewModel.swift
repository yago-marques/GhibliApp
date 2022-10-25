//
//  LetterViewModel.swift
//  GhibliAPP
//
//  Created by Yago Marques on 22/09/22.
//

import Foundation

final class LetterViewModel {

    private let table: LetterViewModelDelegate?
    private(set) var defaults: UserDefaults
    weak var delegate: LetterViewControllerDelegate?
    weak var mainScreenDelegate: MainScreenViewControllerDelegate?
    private var counter: Int = -1
    
    lazy var nextFilm: Film = self.makeFilm() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                if let delegate = self?.delegate, let film = self?.nextFilm, let counter = self?.counter {
                    delegate.addFilmToStack(film: film, counter: counter)
                }
            }
            counter += 1
        }
    }

    init(
        table: LetterViewModelDelegate,
        delegate: LetterViewControllerDelegate? = nil,
        mainScreenDelegate: MainScreenViewControllerDelegate?,
        defaults: UserDefaults = UserDefaults.standard
    ) {
        self.mainScreenDelegate = mainScreenDelegate
        self.table = table
        self.defaults = defaults
    }

    func fetchNextMovieToWatch(tableException: Bool = false) async {
        guard let films = !tableException ? await table?.getMoviesToWatch() : nil else { return }
        nextFilm = films.first ?? self.makeFilm()
    }

    func getWatchedFilms(watchedKey: String = "watchedFilms", decodeException: Bool = false) -> Double? {
        guard let watchedFilmsData = defaults.object(forKey: watchedKey) else { return nil }
        guard let watchedFilms = !decodeException ? try? JSONDecoder().decode([FilmPosition].self, from: watchedFilmsData as! Data) : nil else { return nil }

        return Double(watchedFilms.count)
    }

    func makeFilm() -> Film {
        .init(id: "", title: "", posterImage: Data(), runningTime: "", releaseDate: "", genre: "", bannerImage: Data(), description: "", popularity: 0.00)
    }
}

extension LetterViewModel: UpdateNextFilmDelegate {
    func updateNextFilm(newFilm: Film) {
        self.nextFilm = newFilm
    }
}
