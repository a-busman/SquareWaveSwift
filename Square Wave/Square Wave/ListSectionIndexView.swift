//
//  ListSectionIndexView.swift
//  
//
//  Created by Alex Busman on 2/26/20.
//

import SwiftUI

struct ListSectionIndexView: View {
    @Binding var index: Int
    
    var indices: [Character]
    
    var body: some View {
        VStack {
            ForEach(indicies, id: \.self) { index in
                Text(index)
            }
        }.background(Rectangle())
    }
}

struct ListSectionIndexView_Previews: PreviewProvider {
    static var previews: some View {
        ListSectionIndexView(index: .constant(0))
    }
}
