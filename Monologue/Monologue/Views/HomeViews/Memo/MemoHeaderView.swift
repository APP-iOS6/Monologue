//
//  MemoHeaderView.swift
//  Monologue
//
//  Created by 홍지수 on 10/18/24.
//

import SwiftUI
//칼럼디테일 게시글 뷰
struct MemoHeaderView: View {
    @Binding var memo: Memo
    @Binding var image: UIImage
    @Binding var showShareSheet: Bool
    var isCommentFieldFocused: FocusState<Bool>.Binding
    var commentCount: Int // 댓글 수를 전달받기 위한 변수 추가
    
    @State private var column: Column? = nil
    
    @EnvironmentObject var userInfoStore: UserInfoStore
    @State private var selectedUserInfo: UserInfo = UserInfo(uid: "", email: "", nickname: "", registrationDate: Date(), preferredCategories: [""], profileImageName: "", introduction: "", followers: [""], followings: [""], blocked: [""], likesMemos: [""], likesColumns: [""])
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack() {
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
                    Text(memo.userNickname)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                Text(dateFormatter(memo.date))
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.bottom, 8)
            
            HStack {
                // 댓글 개수를 전달하여 실시간 업데이트가 되도록 수정
                LikeCommentButtons(memo: bindingForColumn(),
                                   column: $column,
                                   isCommentFieldFocused: isCommentFieldFocused)
                Spacer()
                ForEach(memo.categories.prefix(3), id: \.self) { category in
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
            .padding(.bottom, 8)
            .background(Color.white)
            .cornerRadius(12)
            //            .padding(.horizontal, 16)
        }
        .onAppear {
            Task{
                // 이메일을 사용하여 유저 정보를 불러옴
                if let userInfo = try await userInfoStore.loadUsersInfoByEmail(emails: [memo.email]).first {
                    self.selectedUserInfo = userInfo // 불러온 유저 정보 저장
                }
            }
        }
    }
    
    private func bindingForColumn() -> Binding<Memo?> {
        Binding(
            get: {
                return memo
            },
            set: { newValue in
                if let newColumn = newValue {
                    memo = newColumn
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
