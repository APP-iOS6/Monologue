//
//  HomeColunm.swift
//  Monologue
//
//  Created by 강희창 on 10/15/24.
//
import SwiftUI

struct ColumnView: View {
    @EnvironmentObject private var columnStore: ColumnStore
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject private var userInfoStore: UserInfoStore
    @Environment(\.dismiss) private var dismiss
    @Binding var filteredColumns: [Column]  // 필터링된 칼럼을 외부에서 전달받음
    @State private var selectedColumn: Column? = nil
    @State private var index: Int = 0
    
    var sortedFilteredColumns: [Binding<Column>] {
        let columns = filteredColumns.indices.map { index in
            $filteredColumns[index]
        }
        return columns.sorted { $0.wrappedValue.date > $1.wrappedValue.date }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.background.ignoresSafeArea()
            ScrollView {
                VStack {
                    ForEach(sortedFilteredColumns.indices, id: \.self) { index in
                        if index % 3 == 0 {
                            AdBannerView()
                        }
                        
                        NavigationLink(destination: ColumnDetail(column: sortedFilteredColumns[index].wrappedValue)) {
                            PostRow(column: sortedFilteredColumns[index])
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.background)
                    }
                }
                .padding([.leading, .trailing])
            }
        }
    }
}

// 게시물 리스트에서 각 항목을 표시하는 뷰
struct PostRow: View {
    @Binding var column: Column
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .clipShape(Circle())
                
                Text(column.userNickname)
                    .font(.caption2)
                    .foregroundStyle(.black)
                    .font(Font.headline.weight(.bold))
                
                Spacer()
                Text(timeAgoSinceDate(column.date)) // 초단위 삭제
                    .font(.caption)
                    .foregroundColor(.gray)
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
                            .foregroundColor(.accentColor)
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


