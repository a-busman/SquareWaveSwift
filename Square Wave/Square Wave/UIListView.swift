//
//  UIListView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/26/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI
import CoreData

class HeaderCell: UIView {
    var host: UIHostingController<AnyView>?
}

struct HeaderView: View {
    @Binding var didTapPlay: Bool
    @Binding var didTapShuffle: Bool
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 5.0)
                    .foregroundColor(Color(.systemGray6))
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
            }
                .onTapGesture {
                    self.didTapPlay = true
                    
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 5.0)
                .foregroundColor(Color(.systemGray6))
                HStack {
                    Image(systemName: "shuffle")
                    Text("Shuffle")
                }
            }.onTapGesture {
                self.didTapShuffle = true

            }
        }.padding()
    }
}

enum SortType: Int {
    case title
    case game
}

struct UIListViewCellKeypaths {
    var art:   AnyKeyPath
    var title: AnyKeyPath
    var desc:  AnyKeyPath?
}

struct UIListView: UIViewRepresentable {
    @EnvironmentObject var playbackState: PlaybackState
    @Binding var rows: [NSManagedObject]
    @Binding var sortType: Int
    var rowType: NSManagedObject.Type
    var keypaths: UIListViewCellKeypaths
    var showSections = true
    
    // Hack to call updateUIView on playbackState change.
    class RandomClass { }
    let x = RandomClass()

    func makeUIView(context: Context) -> UITableView {
        let collectionView = UITableView(frame: .zero, style: .plain)

        if self.rowType == Track.self,
            let trackRows = self.rows as? [Track] {
            let headerController = UIHostingController(rootView: HeaderView(didTapPlay: Binding(get: {
                false
            }, set: { newValue in
                self.playbackState.currentTracklist = Array(trackRows)
                self.playbackState.shuffleTracks = false
                self.playbackState.play(index: 0)
            }),
            didTapShuffle: Binding(get: {
                false
            }, set: { newValue in
                self.playbackState.currentTracklist = Array(trackRows)
                self.playbackState.nowPlayingTrack = nil
                self.playbackState.shuffleTracks = true
                self.playbackState.shuffle(true)
                self.playbackState.play(index: 0)
            })).frame(height: 75.0))
            
            collectionView.tableHeaderView = headerController.view
        }
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "Song")
        collectionView.tableHeaderView?.frame.size = CGSize(width: collectionView.tableHeaderView!.frame.width, height: 75.0)
        collectionView.tableFooterView = UIView(frame: .zero)

        return collectionView
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        guard let _ = uiView.window else {
            return
        }
        if self.rowType == Track.self {
            if self.sortType != context.coordinator.sortType {
                context.coordinator.sortType = self.sortType
                context.coordinator.rows = self.rows
                context.coordinator.updateSectionTitles()
                uiView.reloadData()
            }
            for cell in uiView.visibleCells {
                if let songCell = cell as? SongTableViewCell {
                    if songCell.info == self.playbackState.nowPlayingTrack {
                        if self.playbackState.isNowPlaying {
                            if !songCell.animating {
                                songCell.play()
                            }
                        } else {
                            songCell.pause()
                        }
                    } else {
                        songCell.stop()
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: self.rows, parent: self, sortType: self.sortType, showSections: self.showSections, rowType: self.rowType, keypaths: self.keypaths)
    }
    
    func didTapRow(track: Track) {
        self.playbackState.currentTracklist = self.rows as! [Track]
        let index = self.rows.firstIndex(of: track) ?? 0
        self.playbackState.play(index: index)
    }

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

        var parent: UIListView
        var rows: [NSManagedObject]
        var filteredRows: [NSManagedObject]
        var sortType: Int
        var showSections: Bool
        var sectionTitles: [String] = []
        var rowsDict: [String : [NSManagedObject]] = [:]
        var rowType: NSManagedObject.Type
        var keypaths: UIListViewCellKeypaths
        var tableView: UITableView? {
            didSet {
                self.tableViewController = self.tableView?.findViewController()
                self.tableViewController?.navigationItem.searchController = self.searchController
                self.tableViewController?.navigationItem.hidesSearchBarWhenScrolling = false
            }
        }
        var tableViewController: UIViewController?
        let searchController = UISearchController(searchResultsController: nil)
        let navController = (UIApplication.shared.windows.first!.rootViewController as? RootViewController)?.navController

        init(rows: [NSManagedObject], parent: UIListView, sortType: Int, showSections: Bool, rowType: NSManagedObject.Type, keypaths: UIListViewCellKeypaths) {
            self.rows = rows
            self.filteredRows = rows
            self.parent = parent
            self.sortType = sortType
            self.showSections = showSections
            self.rowType = rowType
            self.keypaths = keypaths
            super.init()
            
            self.searchController.searchBar.placeholder = "Search"
            self.searchController.obscuresBackgroundDuringPresentation = false
            self.searchController.searchResultsUpdater = self

            if showSections {
                self.updateSectionTitles()
            }
        }
        
        // MARK: - UISearchResultsUpdating Delegate
        func updateSearchResults(for searchController: UISearchController) {
            self.filterContentForSearchText(searchController.searchBar.text!)
        }
        
        func filterContentForSearchText(_ searchText: String, scope: String = "All") {
            if searchText == "" {
                self.filteredRows = self.rows
            } else {
                self.filteredRows = self.rows.filter({(item) -> Bool in
                    if self.rowType == Track.self || self.rowType == Game.self {
                        return (((item[keyPath: self.keypaths.title] as! String).lowercased().contains(searchText.lowercased())) || (item[keyPath: self.keypaths.desc!] as! String).lowercased().contains(searchText.lowercased()))
                    } else {
                        return (item[keyPath: self.keypaths.title] as! String).lowercased().contains(searchText.lowercased())
                    }
                })
            }
            self.updateSectionTitles()
            self.tableView?.reloadData()
        }
        
        func updateSectionTitles() {
            self.rowsDict = [:]
            for object in self.filteredRows {
                var key = ""
                if self.sortType == SortType.title.rawValue || self.rowType != Track.self {
                    if let track = object as? Track {
                        key = String(track.name?.prefix(1) ?? "")
                    } else if let platform = object as? System {
                        key = String(platform.name?.prefix(1) ?? "")
                    } else if let game = object as? Game {
                        key = String(game.name?.prefix(1) ?? "")
                    }
                } else if self.rowType == Track.self {
                    if let track = object as? Track {
                        key = String(track.game?.name?.prefix(1) ?? "")
                    }
                }
                if var values = self.rowsDict[key] {
                    values.append(object)
                    self.rowsDict[key] = values
                } else {
                    self.rowsDict[key] = [object]
                }
            }
            self.sectionTitles = [String](self.rowsDict.keys)
            self.sectionTitles.sort {
                $0 < $1
            }
        }
        private func shouldDisplayAnimation(_ track: Track) -> Bool {
            let shouldAnimate = (track == self.parent.playbackState.nowPlayingTrack)
            return shouldAnimate
        }
        private func shouldAnimate(_ track: Track) -> Bool {
            let shouldAnimate = (track == self.parent.playbackState.nowPlayingTrack) && self.parent.playbackState.isNowPlaying
            return shouldAnimate
        }

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if self.tableView == nil {
                self.tableView = tableView
            }
            if self.showSections {
                let key = self.sectionTitles[section]
            
                if let values = self.rowsDict[key] {
                    return values.count
                }
            } else {
                return self.filteredRows.count
            }
            return 0
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            if self.tableView == nil {
                self.tableView = tableView
            }
            if self.showSections {
                return self.sectionTitles.count
            } else {
                return 1
            }
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if self.tableView == nil {
                self.tableView = tableView
            }
            guard let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell else { return }

            if self.rowType == Track.self,
                let track = cell.info as? Track {
                self.parent.didTapRow(track: track)
                tableView.reloadData()
            } else {
                if self.navController == nil {
                    return
                }

                var predicate: NSPredicate!
                var title = "Songs"
                if self.rowType == System.self,
                    let platform = cell.info as? System {
                    predicate = NSPredicate(format: "system.id == %@", platform.id! as CVarArg)
                    title = platform.name ?? "Songs"
                } else if self.rowType == Game.self,
                    let game = cell.info as? Game {
                    predicate = NSPredicate(format: "game.id == %@", game.id! as CVarArg)
                    title = game.name ?? "Songs"
                }
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let context = delegate.persistentContainer.viewContext
                let songController = UIHostingController(rootView: SongsView(title: title, predicate: predicate).environment(\.managedObjectContext, context).environmentObject(AppDelegate.playbackState))
                self.navController?.pushViewController(songController, animated: true)
            }
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            if self.tableView == nil {
                self.tableView = tableView
            }
            return 50.0
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if self.tableView == nil {
                self.tableView = tableView
            }
            if self.showSections {
                return self.sectionTitles[section]
            }
            return nil
        }
        
        func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            if self.tableView == nil {
                self.tableView = tableView
            }
            if self.sectionTitles.count > 10 {
                return self.sectionTitles
            }
            return nil
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if self.tableView == nil {
                self.tableView = tableView
            }
            guard let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath) as? SongTableViewCell else { return UITableViewCell() }
            var info: NSManagedObject!

            if self.showSections {
                let key = self.sectionTitles[indexPath.section]
                if let values = self.rowsDict[key] {
                    info = values[indexPath.row]
                }
            } else {
                info = self.filteredRows[indexPath.row]
            }
            if info == nil {
                return UITableViewCell()
            }
            tableViewCell.info = info

            tableViewCell.albumArtImage?.image = ListArtView.getImage(for: info[keyPath: self.keypaths.art] as? String ?? "")
            tableViewCell.titleLabel?.text = info[keyPath: self.keypaths.title] as? String
            if self.keypaths.desc != nil {
                tableViewCell.artistLabel?.text = info[keyPath: self.keypaths.desc!] as? String
            } else {
                tableViewCell.artistLabel?.text = nil
            }
            
            if self.rowType == Track.self,
                let track = info as? Track {
                if self.shouldAnimate(track) {
                    tableViewCell.play()
                } else if self.shouldDisplayAnimation(track) {
                    tableViewCell.pause()
                } else {
                    tableViewCell.stop()
                }
            }
            return tableViewCell
        }
    }
}

/*
struct UIListView_Previews: PreviewProvider {
    static var previews: some View {
        UIListView(rows: .constant([]), sortType: .constant(SortType.title.rawValue))
    }
}
*/

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
