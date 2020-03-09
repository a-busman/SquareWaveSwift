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
    case none
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
    @Binding var isEditing: Bool
    var rowType: NSManagedObject.Type
    var keypaths: UIListViewCellKeypaths
    var showSections = true
    var sortFromDesc = false
    var showSearch = true
    var showsHeader = true
    var headerView = UIViewController()
    
    // Hack to call updateUIView on playbackState change.
    class RandomClass { }
    let x = RandomClass()

    func makeUIView(context: Context) -> UITableView {
        let collectionView = UITableView(frame: .zero, style: .plain)

        if self.showsHeader {
            if self.rowType == Track.self,
                let _ = self.rows as? [Track] {
                let headerController = self.makeHeaderView()
                
                collectionView.tableHeaderView = headerController.view
                collectionView.tableHeaderView?.frame.size = CGSize(width: collectionView.tableHeaderView!.frame.width, height: 75.0)
            }
        }
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "Song")
        collectionView.tableFooterView = UIView(frame: .zero)

        return collectionView
    }
    
    func makeHeaderView() -> UIViewController {
        let headerController = UIHostingController(rootView: HeaderView(didTapPlay: Binding(get: {
            false
        }, set: { newValue in
            self.playbackState.currentTracklist = self.rows as! [Track]
            self.playbackState.shuffleTracks = false
            self.playbackState.play(index: 0)
        }),
        didTapShuffle: Binding(get: {
            false
        }, set: { newValue in
            self.playbackState.currentTracklist = self.rows as! [Track]
            self.playbackState.nowPlayingTrack = nil
            self.playbackState.shuffleTracks = true
            self.playbackState.shuffle(true)
            self.playbackState.play(index: 0)
        })).frame(height: 75.0))
        
        return headerController
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        guard let _ = uiView.window else {
            return
        }
        if self.rowType == Track.self {
            if self.sortType != context.coordinator.sortType && self.sortType != SortType.none.rawValue {
                context.coordinator.sortType = self.sortType
                context.coordinator.rows = self.rows
                context.coordinator.filteredRows = self.rows
                context.coordinator.updateSectionTitles()
                uiView.reloadData()
            } else if self.sortType != context.coordinator.sortType && self.sortType == SortType.none.rawValue {
                context.coordinator.rows = self.rows
                context.coordinator.filteredRows = self.rows
                uiView.reloadData()
            }
            if self.rows != context.coordinator.rows {
                context.coordinator.rows = self.rows
                context.coordinator.filteredRows = self.rows
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
        if self.showsHeader && !context.coordinator.isShowingHeader {
            uiView.tableHeaderView = self.makeHeaderView().view
            uiView.tableHeaderView?.frame.size = CGSize(width: uiView.tableHeaderView!.frame.width, height: 75.0)
            context.coordinator.isShowingHeader = true
        } else if !self.showsHeader && context.coordinator.isShowingHeader {
            uiView.tableHeaderView = UIView(frame: .zero)
            context.coordinator.isShowingHeader = false
        }
        
        uiView.setEditing(self.isEditing, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: self.rows, parent: self, sortType: self.sortType, showSections: self.showSections, rowType: self.rowType, keypaths: self.keypaths, showSearch: self.showSearch, showsHeader: self.showsHeader)
    }
    
    func didTapRow(track: Track) {
        self.playbackState.currentTracklist = self.rows as! [Track]
        let index = self.rows.firstIndex(of: track) ?? 0
        NSLog("Index: \(index) in \(self.rows.count) tracks")
        self.playbackState.play(index: index)
    }

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
        var showSearch: Bool
        var parent: UIListView
        var rows: [NSManagedObject]
        var filteredRows: [NSManagedObject]
        var isShowingHeader: Bool
        var sortType: Int
        var showSections: Bool
        var sectionTitles: [String] = []
        var rowsDict: [String : [NSManagedObject]] = [:]
        var rowType: NSManagedObject.Type
        var keypaths: UIListViewCellKeypaths
        var tableView: UITableView? {
            didSet {
                if self.showSearch {
                    self.tableViewController = self.tableView?.findViewController()
                    self.tableViewController?.navigationItem.searchController = self.searchController
                }
            }
        }
        var tableViewController: UIViewController?
        let searchController = UISearchController(searchResultsController: nil)
        let navController = (UIApplication.shared.windows.first!.rootViewController as? RootViewController)?.navController

        init(rows: [NSManagedObject], parent: UIListView, sortType: Int, showSections: Bool, rowType: NSManagedObject.Type, keypaths: UIListViewCellKeypaths, showSearch: Bool, showsHeader: Bool) {
            self.rows = rows
            self.filteredRows = rows
            self.parent = parent
            self.sortType = sortType
            self.showSections = showSections
            self.rowType = rowType
            self.keypaths = keypaths
            self.showSearch = showSearch
            self.isShowingHeader = showsHeader
            super.init()
            
            if self.showSearch {
                self.searchController.searchBar.placeholder = "Search"
                self.searchController.obscuresBackgroundDuringPresentation = false
                self.searchController.searchResultsUpdater = self
            }

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
                if (self.sortType == SortType.title.rawValue && !self.parent.sortFromDesc) || self.rowType != Track.self {
                    if let track = object as? Track {
                        key = String(track.name?.prefix(1) ?? "")
                        if let _ = Int(key) {
                            key = "#"
                        }
                    } else if let platform = object as? System {
                        key = String(platform.name?.prefix(1) ?? "")
                        if let _ = Int(key) {
                            key = "#"
                        }
                    } else if let game = object as? Game {
                        key = String(game.name?.prefix(1) ?? "")
                        if let _ = Int(key) {
                            key = "#"
                        }
                    }
                } else if self.rowType == Track.self {
                    if let track = object as? Track {
                        key = String(track.game?.name?.prefix(1) ?? "")
                        if let _ = Int(key) {
                            key = "#"
                        }
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
                if $0 == "#" || $1 == "#" {
                    return $0 > $1
                } else {
                    return $0 < $1
                }
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
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
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
                var sortFromDesc = false
                if self.rowType == System.self,
                    let platform = cell.info as? System {
                    predicate = NSPredicate(format: "system.id == %@", platform.id! as CVarArg)
                    title = platform.name ?? "Songs"
                    sortFromDesc = true
                } else if self.rowType == Game.self,
                    let game = cell.info as? Game {
                    predicate = NSPredicate(format: "game.id == %@", game.id! as CVarArg)
                    title = game.name ?? "Songs"
                }
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let context = delegate.persistentContainer.viewContext
                let songController = UIHostingController(rootView: SongsView(title: title, predicate: predicate, sortFromDesc: sortFromDesc).environment(\.managedObjectContext, context).environmentObject(AppDelegate.playbackState))
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
        
        func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            let item = self.rows[sourceIndexPath.row]
            
            self.rows.remove(at: sourceIndexPath.row)
            self.rows.insert(item, at: destinationIndexPath.row)
            self.filteredRows = self.rows
            self.parent.rows = self.rows
        }
        
        func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
            return "Remove"
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                self.rows.remove(at: indexPath.row)
                self.filteredRows = self.rows
                self.parent.rows = self.rows
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        
        func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            let titles: [String] = [
                "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"
            ]
            if self.tableView == nil {
                self.tableView = tableView
            }
            if self.showSections && self.sectionTitles.count > 1 {
                return titles
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
                if self.rowType == System.self,
                    let platform = info as? System {
                    tableViewCell.artistLabel?.text = "\(platform.tracks?.count ?? 0) tracks"
                }
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
