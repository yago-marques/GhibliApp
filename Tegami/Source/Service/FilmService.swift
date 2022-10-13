//
//  FilmService.swift
//  Tegami
//
//  Created by Yago Marques on 13/10/22.
//

import Foundation

protocol FilmServicing {
    func getFilms(completion: @escaping (Result<[Film],Error>) -> Void)
}

final class FilmService: FilmServicing {

    weak var api: APICalling?
    weak var delegate: FilmServiceDelegate?
    let decoder = JsonDecoderHelper()

    init(api: APICalling, delegate: FilmServiceDelegate?) {
        self.api = api
        self.delegate = delegate
    }

    func getFilms(completion: @escaping (Result<[Film],Error>) -> Void) {
        delegate?.toggleViewInterective(to: false)
        self.fetchFilms { [weak self] result in
            if let self = self {
                switch result {
                case .success(let filmModels):
                    var businessModels: [Film] = []
                    for filmModel in filmModels {
                        if let ghibli = filmModel.ghibli, let tmdb = filmModel.tmdb {
                            self.getImagesData(from: tmdb) { result in
                                switch result {
                                case .success(let (posterData, bannerData)):
                                    let businessModel = Film(
                                        id: ghibli.id,
                                        title: tmdb.title,
                                        posterImage: posterData,
                                        runningTime: ghibli.runningTime,
                                        releaseDate: ghibli.releaseDate,
                                        genres: self.getGenres(of: tmdb.genreNames),
                                        bannerImage: bannerData,
                                        description: tmdb.overview,
                                        popularity: tmdb.popularity
                                    )

                                    businessModels.append(businessModel)

                                    if businessModels.count == 22 {
                                        completion(.success(businessModels))
                                        self.delegate?.toggleViewInterective(to: true)
                                    }
                                case .failure(let failure):
                                    completion(.failure(failure))
                                }
                            }
                        }
                    }
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }

    func fetchFilms(completion: @escaping (Result<[FilmModel], Error>) -> Void) {
        self.fetchGhibliInfo { [weak self] result in
            if let self = self {
                switch result {
                case .success(let ghibliInfo):
                    var films: [FilmModel] = []

                    for i in 0..<ghibliInfo.count {
                        self.fetchTmdbInfo(originalTitle: ghibliInfo[i].originalTitle) { result in
                            switch result {
                            case .success(let tmdbInfo):
                                let filmInfo = FilmModel(ghibli: ghibliInfo[i], tmdb: tmdbInfo)
                                films.append(filmInfo)

                                if films.count == 22 {
                                    completion(.success(films))
                                }

                            case .failure(let failure):
                                completion(.failure(failure))
                            }
                        }
                    }

                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }

    func fetchGhibliInfo(completion: @escaping (Result<[GhibliInfo], Error>) -> Void) {

        api?.GET(at: UrlEnum.ghibliUrl.rawValue) { [weak self] result in
            if let self = self {
                switch result {
                case .success(let (data, _)):
                    do {
                        let ghibliInfo = try self.decoder.decode([GhibliInfo].self, from: data)
                        completion(.success(ghibliInfo))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }

    func fetchTmdbInfo(
        originalTitle: String,
        completion: @escaping (Result<TmdbResult?, Error>) -> Void
    ) {

        api?.GET(
            at: UrlEnum.tmbdMovie.rawValue,
            queries: [
                ("api_key", "2fb0d7c0095f63e9c881bb4317a570a9"),
                ("language", "pt-BR"),
                ("query", originalTitle),
                ("page", "1")
            ]
        ) { [weak self] result in
            if let self = self {
                switch result {
                case .success(let (data, _)):
                    do {
                        let tmdbInfo = try self.decoder.decode(TmdbInfo.self, from: data)
                        self.transformGenres(ids: tmdbInfo.results.first!.genreIds) { genreResult in
                            switch genreResult {
                            case .success(let stringGenreList):
                                tmdbInfo.results.first?.genreNames = stringGenreList
                                completion(.success(tmdbInfo.results.first))
                            case .failure(let failure):
                                completion(.failure(failure))
                            }
                        }

                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }

    func fetchGenres(completion: @escaping (Result<[GenreInfo], Error>) -> Void) {

        api?.GET(
            at: UrlEnum.tmdbGenre.rawValue,
            queries: [
                ("api_key","2fb0d7c0095f63e9c881bb4317a570a9"),
                ("language","pt-BR")
            ]
        ) { [weak self] result in
            if let self = self {
                switch result {
                case .success(let (data, _)):
                    do {
                        let genreInfo = try self.decoder.decode(GenreModel.self, from: data)
                        completion(.success(genreInfo.genres))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }

    }

    func transformGenres(
        ids: [Int],
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        self.fetchGenres { result in
            switch result {
            case .success(let genreTable):
                let idsToTransform: [Int] = ids.count >= 2 ? [ids[0], ids[1]] : [ids[0]]

                let genreNames: [String] = idsToTransform.map { id in
                    var genreName = "unknown"
                    for genre in genreTable where genre.id == id {
                        genreName = genre.name
                    }
                    return genreName
                }

                completion(.success(genreNames))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }

    }

    func getGenres(of genreNames: [String]) -> String {
        var result = ""

        if genreNames.count == 2 {
            result = "\(genreNames[0]) - \(genreNames[1])"
        } else {
            result = genreNames[0]
        }

        return result
    }

    func getImagesData(
        from tmdbInfo: TmdbResult,
        completion: @escaping (Result<(poster: Data, banner: Data), Error>) -> Void
    ) {
        let posterPath = UrlEnum.baseImage.rawValue.appending(tmdbInfo.posterPath)
        let bannerPath = UrlEnum.baseImage.rawValue.appending(tmdbInfo.backdropPath)

        api?.GET(at: posterPath, headers: [:]) { [weak self] result in
            if let self = self {
                switch result {
                case .success(let (posterData, _)):
                    self.api?.GET(at: bannerPath, headers: [:]) { result in
                        switch result {
                        case .success(let (bannerData, _)):
                            completion(.success((posterData, bannerData)))
                        case .failure(let failure):
                            completion(.failure(failure))
                        }
                    }
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }

}
