//
//  MemoView.swift
//  Monologue
//
//  Created by 홍지수 on 10/15/24.
//

import SwiftUI
import OrderedCollections

class FilteredMemoStore: ObservableObject {
    var memoStore: MemoStore = .init()
    private var memoImageStore: MemoImageStore = .init()
    
    @Published var filteredMemos: [Memo] = []
    @Published var images: [UIImage] = []
    @Published var isLoadingImages: Bool = false
        
    func setFilteredMemos(filters: [String], userEmail: String) {
        Task {
            if filters == ["전체"] {
                do {
                    let memos = try await memoStore.loadMemos().filter { memo in
                        memo.email != userEmail
                    }
                    
                    DispatchQueue.main.async {
                        // 시간 순서대로 memo가 배열되게 함.
                        self.filteredMemos = memos.sorted { $0.date > $1.date }
                        self.loadImagesForMemos()
                    }
                } catch {
                    print("loadMemos error: \(error)")
                }
            } else {
                do {
                    let memos = try await memoStore.loadMemos().filter { memo in
                        memo.categories.contains { filters.contains($0) } && memo.email != userEmail
                    }
                    DispatchQueue.main.async {
                        self.filteredMemos = memos.sorted { $0.date > $1.date }
                        self.loadImagesForMemos()
                    }
                } catch {
                    print("loadMemos error: \(error)")
                }
            }
        }
    }
    
    func loadImagesForMemos() {
        if self.filteredMemos.count != 0 {
            DispatchQueue.main.async {
                self.images = Array(repeating: UIImage(), count: self.filteredMemos.count)
                let dispatchGroup = DispatchGroup()
                for (index, memo) in self.filteredMemos.enumerated() {
                    dispatchGroup.enter()
                    self.memoImageStore.loadImage(imageName: memo.id) { image in
                        if let image = image {
                            self.images[index] = image
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.images = self.images.compactMap { $0 }
                }
            }
        } else {
            images = []
        }
    }
    
    @MainActor
    func setUserMemos(userMemos: [Memo]) {
        DispatchQueue.main.async {
            Task {
                self.filteredMemos = userMemos
                self.loadImagesForMemos()
            }
        }
    }
    
    func setSearchMemos(searchMemos: [Memo]) {
        DispatchQueue.main.async {
            self.filteredMemos = searchMemos
            self.loadImagesForMemos()
        }
    }
}

struct MemoView: View {
    @StateObject private var filteredMemoStore: FilteredMemoStore = .init()
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var memoStore: MemoStore
    @Binding var filters: [String]?
    var userMemos: [Memo]?
    var searchMemos: [Memo]?
    
    var searchColumns: [Column]?
    
    var searchText: String = ""
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            MasonryLayout(columns: 2, spacing: 16) {
                if (filteredMemoStore.images.count != 0) && (filteredMemoStore.images.count == filteredMemoStore.filteredMemos.count) {
                    
                    ForEach(filteredMemoStore.filteredMemos.indices, id: \.self) { index in
                        if index == 3 {  // 3번째 메모 뒤에 광고 배너 삽입
                            AdBannerView()
                        }
                        NavigationLink(destination: MemoDetailView(memo: $filteredMemoStore.filteredMemos[index], image: $filteredMemoStore.images[index])) {
                            ZStack {
                                VStack(alignment: .trailing) {
                                    let image = filteredMemoStore.images[index]
                                    
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: UIScreen.main.bounds.width / 2 - 24, height: nil)
                                        .clipped()
                                        .cornerRadius(12)
                                        .scaledToFit()
                                    HStack {
                                        Image(systemName: "bubble.right")
                                            .resizable()
                                            .frame(width: 10, height: 10)
                                            .padding(.leading, 8)
                                        Text("\(filteredMemoStore.filteredMemos[index].comments?.count ?? 0)")
                                            .font(.caption2)
                                        Image(systemName: "heart")
                                            .resizable()
                                            .frame(width: 10, height: 10)
                                        Text("\(filteredMemoStore.filteredMemos[index].likes.count)")
                                            .font(.caption2)
                                        Spacer()
                                        Text("\(filteredMemoStore.filteredMemos[index].userNickname)")
                                            .font(.caption2)
                                            .padding(.trailing, 8)
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            if let tempFilters = filters {
                filteredMemoStore.setFilteredMemos(filters: tempFilters, userEmail: authManager.email)
            }
            
            if let userMemos = userMemos {
                filteredMemoStore.setUserMemos(userMemos: userMemos)
            }
        }
        .onChange(of: filters) {
            print("필터 : \(String(describing: filters))")
            if let tempFilters = filters {
                filteredMemoStore.setFilteredMemos(filters: tempFilters, userEmail: authManager.email)
            }
        }
        .onChange(of: userMemos) {
            if let userMemos = userMemos {
                filteredMemoStore.setUserMemos(userMemos: userMemos)
            }
        }
        .onChange(of: searchMemos) {
            if let searchMemos = searchMemos {
                filteredMemoStore.setSearchMemos(searchMemos: searchMemos)
            }
        }
        .refreshable {
            await refreshMemos()
        }
    }
    
    func refreshMemos() async {
        Task {
            if let tempFilters = filters {
                filteredMemoStore.setFilteredMemos(filters: tempFilters, userEmail: authManager.email)
            }
            
            if !searchText.isEmpty {                
                do {
                    let searchMemos = try await memoStore.loadMemosByContent(content: searchText)
                    filteredMemoStore.setSearchMemos(searchMemos: searchMemos)
                } catch {
                    print("refreshMemos: \(error.localizedDescription)")
                }
            }
            
        }
    }
}
