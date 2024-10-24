//
//  ColumnHeaderView.swift
//  Monologue
//
//  Created by 강희창 on 10/17/24.
//

import SwiftUI
//칼럼디테일 게시글 뷰
struct ColumnHeaderView: View {
    @Binding var column: Column
    @Binding var showShareSheet: Bool
    var isCommentFieldFocused: FocusState<Bool>.Binding
    var commentCount: Int // 댓글 수를 전달받기 위한 변수 추가
    @EnvironmentObject var userInfoStore: UserInfoStore
    @State private var memo: Memo? = nil
    @State private var isEditMode: Bool = false
    
    @State private var selectedUserInfo: UserInfo = UserInfo(uid: "", email: "", nickname: "", registrationDate: Date(), preferredCategories: [""], profileImageName: "", introduction: "", followers: [""], followings: [""], blocked: [""], likesMemos: [""], likesColumns: [""])
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                NavigationLink {
                    MyPageView(userInfo: selectedUserInfo)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    if selectedUserInfo.profileImageName.isEmpty {
                        Image(systemName: "person.fill") // 기본 시스템 이미지
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .padding(.trailing, 8)
                            .foregroundStyle(.accent)
                    } else {
                        Image(selectedUserInfo.profileImageName) // 사용자 이미지
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .padding(.trailing, 8)
                    }
                    
                    Text(column.userNickname)
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                Spacer()
                Text(dateFormatter(column.date))
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            VStack(alignment: .leading) {
                Text(column.title)
                    .font(.body)
                    .bold()
                    .padding(.bottom, 5)
                Text(column.content)
                    .font(.body)
                    .foregroundColor(.black)
            }
            .padding(.bottom, 8)
            
            HStack {
                // 댓글 개수를 전달하여 실시간 업데이트가 되도록 수정
                LikeCommentButtons(memo: $memo,
                                   column: bindingForColumn(),
                                   isCommentFieldFocused: isCommentFieldFocused)
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
            .padding(.bottom, 8)
            .background(Color.white)
            .cornerRadius(12)
        }
        .onAppear {
            Task{
                // 이메일을 사용하여 유저 정보를 불러옴
                if let userInfo = try await userInfoStore.loadUsersInfoByEmail(emails: [column.email]).first {
                    self.selectedUserInfo = userInfo // 불러온 유저 정보 저장
                }
            }
        }
    }
    
    
    private func bindingForColumn() -> Binding<Column?> {
        Binding(
            get: {
                return column
            },
            set: { newValue in
                if let newColumn = newValue {
                    column = newColumn
                }
            }
        )
    }
    
    private func dateFormatter(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
}
