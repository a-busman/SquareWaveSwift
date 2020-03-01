//
//  UIListView.swift
//  Square Wave
//
//  Created by Alex Busman on 2/26/20.
//  Copyright © 2020 Alex Busman. All rights reserved.
//

import SwiftUI

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

struct UIListView: UIViewRepresentable {
    @EnvironmentObject var playbackState: PlaybackState
    @Binding var rows: [Track]
    @Binding var sortType: Int
    var showSections = true
    
    // Hack to call updateUIView on playbackState change.
    class RandomClass { }
    let x = RandomClass()

    func makeUIView(context: Context) -> UITableView {
        
        let headerController = UIHostingController(rootView: HeaderView(didTapPlay: Binding(get: {
            false
        }, set: { newValue in
            self.playbackState.currentTracklist = Array(self.rows)
            self.playbackState.shuffleTracks = false
            self.playbackState.play(index: 0)
        }),
        didTapShuffle: Binding(get: {
            false
        }, set: { newValue in
            self.playbackState.currentTracklist = Array(self.rows)
            self.playbackState.nowPlayingTrack = nil
            self.playbackState.shuffleTracks = true
            self.playbackState.shuffle(true)
            self.playbackState.play(index: 0)
        })).frame(height: 75.0))
        let collectionView = UITableView(frame: .zero, style: .plain)
        collectionView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: LibraryView.miniViewPosition, right: 0.0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "Song")
        collectionView.tableHeaderView = headerController.view
        collectionView.tableHeaderView?.frame.size = CGSize(width: collectionView.tableHeaderView!.frame.width, height: 75.0)
        return collectionView
    }

    func updateUIView(_ uiView: UITableView, context: Context) {
        guard let _ = uiView.window else {
            return
        }
        if self.sortType != context.coordinator.sortType {
            context.coordinator.sortType = self.sortType
            context.coordinator.rows = self.rows
            context.coordinator.updateSectionTitles()
            uiView.reloadData()
        }
        for cell in uiView.visibleCells {
            if let songCell = cell as? SongTableViewCell {
                if songCell.track == self.playbackState.nowPlayingTrack {
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

    func makeCoordinator() -> Coordinator {
        Coordinator(rows: self.rows, parent: self, sortType: self.sortType, showSections: self.showSections)
    }
    
    func didTapRow(track: Track) {
        self.playbackState.currentTracklist = self.rows
        let index = self.rows.firstIndex(of: track) ?? 0
        self.playbackState.play(index: index)
    }

    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {

        var parent: UIListView
        var rows: [Track]
        var sortType: Int
        var showSections: Bool
        var sectionTitles: [String] = []
        var rowsDict: [String : [Track]] = [:]

        init(rows: [Track], parent: UIListView, sortType: Int, showSections: Bool) {
            self.rows = rows
            self.parent = parent
            self.sortType = sortType
            self.showSections = showSections
            super.init()
            
            if showSections {
                self.updateSectionTitles()
            }
        }
        
        func updateSectionTitles() {
            self.rowsDict = [:]
            for track in self.rows {
                var key = ""
                if self.sortType == SortType.title.rawValue {
                    key = String(track.name?.prefix(1) ?? "")
                } else {
                    key = String(track.game?.name?.prefix(1) ?? "")
                }
                if var values = self.rowsDict[key] {
                    values.append(track)
                    self.rowsDict[key] = values
                } else {
                    self.rowsDict[key] = [track]
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
            if self.showSections {
                let key = self.sectionTitles[section]
            
                if let values = self.rowsDict[key] {
                    return values.count
                }
            } else {
                return self.rows.count
            }
            return 0
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            if self.showSections {
                return self.sectionTitles.count
            } else {
                return 1
            }
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if let cell = tableView.cellForRow(at: indexPath) as? SongTableViewCell,
                let track = cell.track {
                self.parent.didTapRow(track: track)
                tableView.reloadData()
            }
        }

        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50.0
        }
        
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            if self.showSections {
                return self.sectionTitles[section]
            }
            return nil
        }
        
        func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            if self.sectionTitles.count > 10 {
                return self.sectionTitles
            }
            return nil
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "Song", for: indexPath) as? SongTableViewCell else { return UITableViewCell() }
            var track: Track!

            if self.showSections {
                let key = self.sectionTitles[indexPath.section]
                if let values = self.rowsDict[key] {
                    track = values[indexPath.row]
                }
            } else {
                track = self.rows[indexPath.row]
            }
            
            tableViewCell.track = track

            tableViewCell.albumArtImage?.image = ListArtView.getImage(for: track.system?.name ?? "")
            tableViewCell.titleLabel?.text = track.name
            tableViewCell.artistLabel?.text = track.game?.name
            
            if self.shouldAnimate(track) {
                tableViewCell.play()
            } else if self.shouldDisplayAnimation(track) {
                tableViewCell.pause()
            } else {
                tableViewCell.stop()
            }
            return tableViewCell
        }
    }
}

struct UIListView_Previews: PreviewProvider {
    static var previews: some View {
        UIListView(rows: .constant([]), sortType: .constant(SortType.title.rawValue))
    }
}
