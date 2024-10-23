//
//  Searc.swift
//  Monologue
//
//  Created by 홍지수 on 10/16/24.
//

import SwiftUI

enum field {
    case search
}

struct SearchView: View {
    @EnvironmentObject private var memoStore: MemoStore
    @EnvironmentObject private var columnStore: ColumnStore
    
    @State private var isTruncated: Bool? = nil
    @State private var isExpended: Bool = false
    @State private var scrollPosition: CGPoint = .zero
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @State var recentWatchView: [String] = []
    @State var selectedSegment: String = "메모"
    @FocusState var focusField: field?
    @FocusState private var isSearchFieldFocused: Bool
    
    // 검색 결과 게시물들
    @State private var searchMemos: [Memo] = []
    @State private var searchColumns: [Column] = []
    @State private var selectedCategories: [String]? = ["전체"]
    
    // 더미데이터----------------------------------
    @State var recentSearchList: [String] = [
        "시인", "한강 작가", "채식주의자", "흰", "문인", "사랑의 기술", "철학", "율리시스 무어", "카프카", "바퀴벌레", "존재적 사랑"
    ]
    let recommandSearchList: [String] = [
        "시인", "한강 작가", "채식주의자", "흰", "문인", "사랑의 기술", "철학", "율리시스 무어", "카프카", "바퀴벌레", "존재적 사랑"
    ]
    
    var filteredSuggestions: [String] {
        let allContents = (memoStore.memos.map { $0.content } + columnStore.columns.map { $0.content }).joined(separator: " ")
        let allWords = Set(allContents.components(separatedBy: .whitespacesAndNewlines))
        
        let matchingWords = allWords.filter { word in
            word.lowercased().contains(searchText.lowercased()) && !searchText.isEmpty
        }
        // 자음 순으로 정렬하고 최대 10개의 결과만 반환
        return Array(matchingWords.sorted().prefix(10))
    }
    
    //------------------------------------------
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                ZStack {
                    Color.background
                        .ignoresSafeArea()
//                    ScrollView {
                    VStack {
                        // MARK: - 검색 필드
//                        Spacer()
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .foregroundStyle(Color.white)
                                    .frame(width: isSearching ? proxy.size.width * 0.78 : proxy.size.width * 0.92)
                                    .frame(height: proxy.size.height * 0.05)
                                HStack {
                                    Image(systemName:"magnifyingglass")
                                        .foregroundStyle(.accent)
                                        .animation(.easeInOut(duration: 0.3), value: isSearching)
                                    TextField("글 검색", text: $searchText)
                                        .focused($focusField, equals: .search)
                                        .frame(width: isSearching ? proxy.size.width * 0.56 : proxy.size.width * 0.72)
                                        .autocorrectionDisabled()
                                        .transition(.move(edge: .trailing))
                                        .animation(.easeInOut(duration: 0.3), value: isSearching)
                                        .onChange(of: searchText) { value in
                                            if !value.isEmpty {
                                                isSearching = true
                                            }
                                        }
                                    if !searchText.isEmpty {
                                        clearTextButton()
                                            .foregroundStyle(.accent)
                                    }
                                }
                                .frame(width: isSearching ? proxy.size.width * 0.78 : proxy.size.width * 0.92)
                                .frame(height: proxy.size.height * 0.05)
                            }
                            .animation(.easeInOut, value: isSearching)
                            // 취소 버튼
                            if isSearching {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isSearching = false
                                        searchText = "" // 검색어 초기화
                                    }
                                } label : {
                                    Text("취소")
                                        .padding(10)
                                }
                                .transition(.move(edge: .trailing))
                            }
                        }
                        .frame(width: proxy.size.width)
                        
                        //MARK: - 최근 검색어
                        if searchText.isEmpty {
                            Divider()
                            if !recentSearchList.isEmpty {
                                HStack {
                                    Text("최근 검색어")
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                    Button {
                                        self.recentSearchList.removeAll()
                                    } label : {
                                        Text("지우기")
                                            .font(.subheadline)
                                    }
                                }
                                .padding()
                                Divider()
                                
                                // 최근 검색
                                ForEach(recentSearchList, id:\.self) { search in
                                    Button {
                                        searchText = search
                                        // 엔터 시 검색어 관련 게시글로 넘어가게 하는 로직
                                        
                                    } label : {
                                        VStack {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .resizable()
                                                    .frame(width: 30, height: 30)
                                                Text(search)
                                                    .font(.subheadline)
                                                Spacer()
                                            }
                                            .font(.system(size: 22))
                                            .foregroundStyle(.accent)
                                            .padding(.horizontal)
                                            .padding(.vertical, 5)
                                            
                                            Divider()
                                        }
                                    }
                                }
                            }
                            //MARK: - view List
                        } else {
                            CustomSegmentView(segment1: "메모", segment2: "칼럼", selectedSegment: $selectedSegment)
                            // 세그먼트 피커
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    MemoView(filters: $selectedCategories, searchMemos: searchMemos)
                                        .frame(width: geometry.size.width)
                                        .clipped()
                                    ColumnView(filters:$selectedCategories, userColumns: searchColumns)
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
                    }
                }
                .toolbarTitleDisplayMode(.automatic)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer() // 왼쪽 공간을 확보하여 버튼을 오른쪽으로 이동
                        Button("완료") {
                            isSearchFieldFocused = false // 키보드 숨기기
                        }
                    }
                }
                .onChange(of: searchText) { oldValue, newValue in
                    Task {
                        do {
                            searchMemos = try await memoStore.loadMemosByContent(content: newValue)
                            searchColumns = try await columnStore.loadColumnsByContent(content: newValue)
                        } catch {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

extension SearchView {
    
    @ViewBuilder
    private func recommandSearchButton(_ text: String) -> some View {
        Button {
            self.searchText = text
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.accent)
                Text(text)
                    .foregroundStyle(.black)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .font(.system(size: 20))
            
        }
    }
    
    @ViewBuilder
    private func clearTextButton() -> some View {
        Button {
            self.searchText = ""
        } label : {
            Image(systemName: "x.circle.fill")
        }
    }
    
    // 검색어 맞는 게시글 반환
//    private func loadSearchContent() async {
//        do {
//            searchMemos = try await memoStore.loadMemosByContent(content: searchText)
//            searchColumns = try await columnStore.loadColumnsByContent(content: searchText)
//        } catch {
//            print("Error: \(error.localizedDescription)")
//        }
//    }
}

//
//#Preview {
//    SearchView()
//}
