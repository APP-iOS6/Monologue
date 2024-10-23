//
//  HomeView.swift
//  Monologue
//
//  Created by Hyunwoo Shin on 10/14/24.
//

import SwiftUI
import OrderedCollections

// 메모/칼럼: 해당 글이 아니면 신고하기 버튼 활성, 해당 글이면 삭제하기
enum ShareType {
    case memo(Memo)
    case column(Column)
}

struct HomeView: View {
    @EnvironmentObject private var memoStore: MemoStore
    @EnvironmentObject private var columnStore: ColumnStore
    @EnvironmentObject private var memoImageStore: MemoImageStore
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @Binding var selectedTab: Int
    
    @State private var memos: [Memo] = []
    @State private var isScrollingDown = false
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State var selectedSegment: String = "메모"
    @State private var selectedCategories: [String]? = ["전체"]
    @State var filteredColumns: [Column] = []
    @State var dict: OrderedDictionary = [
        "전체": true,
        "오늘의 주제": false,
        "에세이": false,
        "사랑" : false,
        "자연" : false,
        "시" : false,
        "자기계발" : false,
        "추억" : false,
        "소설": false,
        "SF": false,
        "IT": false,
        "기타": false,
    ]
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TopBarView(searchText: $searchText, isSearching: $isSearching, selectedSegment: $selectedSegment)
                        .transition(.move(edge: .top))
                    
                    // 필터 버튼
                    categoryView(dict: $dict)
                        .padding(.bottom)
                        .onChange(of: dict) { oldValue, newValue in
                            selectedCategories = newValue.filter { $0.value }.map { $0.key }
                            
                            let otherSelected = newValue.filter { $0.key != "전체" && $0.value }.count
                            if otherSelected == newValue.count - 1 {
                                // 모든 항목이 선택되면 "전체"를 활성화하고 나머지 항목을 비활성화
                                for (key, _) in newValue {
                                    dict[key] = (key == "전체")
                                }
                            }
                            
                            if selectedCategories == ["전체"] {
                                Task {
                                    self.filteredColumns = try await columnStore.loadColumn()
                                }
                            } else {
                                Task {
                                    self.filteredColumns = try await columnStore.loadColumn().filter { column in
                                        column.categories.contains { selectedCategories!.contains($0) }
                                    }
                                }
                            }
                        }
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            MemoView(filters: $selectedCategories)
                                .frame(width: geometry.size.width)
                                .clipped()
                            
                            ColumnView(filters: $selectedCategories)
                                .frame(width: geometry.size.width)
                                .clipped()
                        }
                        .frame(width: geometry.size.width * 2)
                        .offset(x: selectedSegment == "메모" ? 0 : -geometry.size.width)
                        .animation(.easeInOut, value: selectedSegment)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width > 100 {
                                        selectedSegment = "메모"
                                    } else if value.translation.width < -100 {
                                        selectedSegment = "칼럼"
                                    }
                                }
                        )
                    }
                }
                VStack {
                    if isSearching {
                        SearchView(searchText: $searchText, isSearching: $isSearching)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            UIScrollView.appearance().bounces = true
            
            Task {
                self.filteredColumns = try await columnStore.loadColumn()
                self.filteredColumns = self.filteredColumns.filter { $0.email != userInfoStore.userInfo?.email }
            }
        }
    }
}

//#Preview {
//    HomeView()
//        .environmentObject(AuthManager())
//        .environmentObject(UserInfoStore())
//        .environmentObject(MemoStore())
//        .environmentObject(ColumnStore())
//        .environmentObject(CommentStore())
//}
