//
//  FollowListView.swift
//  Monologue
//
//  Created by Hyojeong on 10/15/24.
//

import SwiftUI

struct FollowListView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSegment = "팔로워" // 초기 선택
    let segments = ["팔로워", "팔로잉"] // 세그먼트 버튼
    
    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            
            // 커스텀 Segment
            GeometryReader { geometry in
                HStack {
                    ForEach(segments, id: \.self) { segment in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSegment = segment
                            }
                        } label: {
                            Text(segment)
                                .font(.system(size: 16))
                                .foregroundStyle(.accent)
                                .frame(maxWidth: .infinity) // 각 탭을 동일한 너비로 설정
                        }
                    }
                }
                .overlay(
                    // 전체 너비 밑줄
                    Rectangle()
                        .fill(.accent.opacity(0.2))
                        .frame(width: geometry.size.width, height: 1) // 전체 너비
                        .offset(y: 13),
                    alignment: .bottomLeading
                )
                .overlay(
                    Rectangle()
                        .fill(.accent)
                        .frame(width: geometry.size.width / 2, height: 2)
                        .offset(x: selectedSegment == "팔로워" ? 0 : geometry.size.width / 2, y: 13),
                    alignment: .bottomLeading
                )
            }
            
            ScrollView {
                VStack {
                    if selectedSegment == "팔로워" {
                        // 팔로워 뷰
                        
                    } else {
                        // 팔로잉 뷰
                        
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("북극성") // nickname 데이터로 변경 예정
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 기본 백 버튼 숨기기
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FollowListView()
    }
}
