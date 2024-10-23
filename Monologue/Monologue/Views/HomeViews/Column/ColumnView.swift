//
//  HomeColunm.swift
//  Monologue
//
//  Created by 강희창 on 10/15/24.
//
import SwiftUI

class FilteredColumnStore: ObservableObject {
    var columnStore: ColumnStore = .init()
    @Published var filteredColumns: [Column] = []
    
    func setFilteredMemos(filters: [String], userEmail: String) {
        Task {
            if filters == ["전체"] {
                do {
                    let columns = try await columnStore.loadColumn().filter { column in
                        column.email != userEmail
                    }
                    
                    DispatchQueue.main.async {
                        
                        // 시간 순서대로 memo가 배열되게 함.
                        self.filteredColumns = columns.sorted { $0.date > $1.date }
                    }
                } catch {
                    print("loadMemos error: \(error)")
                }
            } else {
                do {
                    let columns = try await columnStore.loadColumn().filter { column in
                        column.categories.contains { filters.contains($0) } && column.email != userEmail
                    }
                    DispatchQueue.main.async {
                        self.filteredColumns = columns.sorted { $0.date > $1.date }
                    }
                } catch {
                    print("loadMemos error: \(error)")
                }
            }
        }
    }
    
    func setUserColumns(userColumns: [Column]) {
        DispatchQueue.main.async {
            self.filteredColumns = userColumns
        }
    }
}

struct ColumnView: View {
    @StateObject private var filteredColumnStore: FilteredColumnStore = .init()
    @EnvironmentObject private var columnStore: ColumnStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @Binding var filters: [String]?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColumn: Column? = nil
    @State private var selectedUserInfo: UserInfo = UserInfo(uid: "", email: "", nickname: "", registrationDate: Date(), preferredCategories: [""], profileImageName: "", introduction: "", followers: [""], followings: [""], blocked: [""], likesMemos: [""], likesColumns: [""])
    
    var userColumns: [Column]?
//    
//    var sortedFilteredColumns: [Binding<Column>] {
//        let columns = filteredColumns.indices.map { index in
//            $filteredColumns[index]
//        }
//        return columns.sorted { $0.wrappedValue.date > $1.wrappedValue.date }
//    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack {
                    ForEach(filteredColumnStore.filteredColumns.indices, id: \.self) { index in
                        if index % 3 == 2 {
                            AdBannerView()
                        }
                        
                        NavigationLink(destination: ColumnDetail(column: $filteredColumnStore.filteredColumns[index].wrappedValue)) {
                            PostRow(column: $filteredColumnStore.filteredColumns[index])
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.background)
                    }
                }
                .padding([.leading, .trailing])
            }
            .padding(.bottom)
        }
        .onAppear {
            if let tempFilters = filters {
                filteredColumnStore.setFilteredMemos(filters: tempFilters, userEmail: authManager.email)
            }
            
            if let userColumns = userColumns {
                filteredColumnStore.setUserColumns(userColumns: userColumns)
            }
        }
        .onChange(of: filters) {
            print("필터 : \(String(describing: filters))")
            if let tempFilters = filters {
                filteredColumnStore.setFilteredMemos(filters: tempFilters, userEmail: authManager.email)
            }
        }
        .onChange(of: userColumns) {
            if let userColumns = userColumns {
                filteredColumnStore.setUserColumns(userColumns: userColumns)
            }
        }
    }
}

// 게시물 리스트에서 각 항목을 표시하는 뷰
struct PostRow: View {
    @Binding var column: Column
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @State private var selectedUserInfo: UserInfo = UserInfo(uid: "", email: "", nickname: "", registrationDate: Date(), preferredCategories: [""], profileImageName: "", introduction: "", followers: [""], followings: [""], blocked: [""], likesMemos: [""], likesColumns: [""])
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(selectedUserInfo.profileImageName)
                    .resizable()
                    .frame(width: 15, height: 15)
                    .clipShape(Circle())
                
                Text(column.userNickname)
                    .font(.caption2)
                    .foregroundStyle(.black)
                    .font(Font.headline.weight(.bold))
                
                Spacer()
                Text(timeAgoSinceDate(column.date)) // 초단위 삭제
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            Text(column.title)
                .font(.body)
                .foregroundStyle(.black)
                .font(Font.headline.weight(.bold))
                .padding(.bottom, 2)
            HStack {
                Text(column.content) // 칼럼 내용 표시
                    .font(.caption)
                    .foregroundColor(.black)
                    .font(Font.caption.weight(.thin))
                    .lineLimit(3) // 3 줄까지만 표시
            }
            .padding(.leading, 2)
            
            HStack {
                HStack {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                    Text("\(String(describing: column.comments?.count ?? 0))")  // 댓글 수 표시
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                HStack {
                    Image(systemName: "heart")
                        .foregroundColor(.gray)
                    Text("\(column.likes.count)")  // 좋아요 수 표시
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                ForEach(column.categories.prefix(3), id: \.self) { category in
                    if !category.isEmpty {
                        Text(category)
                            .font(.footnote)
                            .foregroundColor(.black)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(.gray, lineWidth: 0.5))
        .padding(.vertical, 1)        
        .onAppear {
            Task{
                // 이메일을 사용하여 유저 정보를 불러옴
                if let userInfo = try await userInfoStore.loadUsersInfoByEmail(emails: [column.email]).first {
                    self.selectedUserInfo = userInfo // 불러온 유저 정보 저장
                }
            }
        }
    }
    func timeAgoSinceDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)년 전"
        } else if let month = components.month, month > 0 {
            return "\(month)달 전"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)주 전"
        } else if let day = components.day, day > 0 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        } else {
            return "방금 전"
        }
    }
}
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleColumns = [
//            Column(title: "title1", content: "Sample Column 1", userNickname: "User1", font: "", backgroundImageName: "", categories: ["에세이"], likes: [], comments: ["Comment 1", "Comment 2"], date: Date()),
//            Column(title: "title2", content: "Sample Column 2", userNickname: "User2", font: "", backgroundImageName: "", categories: ["사랑"], likes: ["User1"], comments: [], date: Date())
//        ]
//
//        NavigationView {
//            ColumnView(filteredColumns: sampleColumns)
//                .environmentObject(ColumnStore())
//                .environmentObject(AuthManager())
//                .environmentObject(UserInfoStore())
//        }
//    }
//}


