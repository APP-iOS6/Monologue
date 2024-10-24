//
//  ShareSheetView.swift
//  Monologue
//
//  Created by 강희창 on 10/17/24.
//

import SwiftUI

struct ShareSheetView: View {
    @EnvironmentObject var memoStore: MemoStore
    @EnvironmentObject var columnStore: ColumnStore
    @EnvironmentObject var authManager: AuthManager
    
    let shareType: ShareType
    @Binding var isPresented: Bool
    @Binding var isColumnModifyingView: Bool
    @Binding var itemSheet: Bool
    @State private var showReportSheet = false
    let sharedString: String = "MONOLOG"
    
    var onDelete: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer().frame(height: 16) // 상단에 고정된 여백 추가
                
                ShareLink(item: sharedString) {
                    Text("공유하기")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                }
                
                Divider()
                
                if case let .column(column) = shareType {
                    if column.email == authManager.email {
                        Button {
                            isColumnModifyingView = true
                        } label: {
                            Text("수정하기")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.red)
                        }
                        .onAppear {
                            itemSheet = true
                        }
                    }
                }
                Divider()
                
                // 신고하기 버튼 표시
                if  shouldShowReportButton() {
                    Button(action: {
                        showReportSheet = true
                    }) {
                        Text("신고하기")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                    }
                    Divider()
                } else {
                    Button(action: {
                        Task {
                            switch shareType {
                            case .memo(let memo):
                                try await memoStore.deleteMemo(memoId: memo.id) // memo.id로 메모 삭제
                            case .column(let column):
                                try await columnStore.deleteColumn(columnId: column.id) // column.id로 칼럼 삭제
                            }
                            isPresented = false // 시트 닫기
                            onDelete?()
                        }
                    }) {
                        Text("삭제하기")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.red)
                    }
                    Divider()
                }
                Button(action: {
                    isPresented = false
                }) {
                    Text("취소")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                }
                
                Spacer().frame(height: 16) // 하단 여백 추가
            }
            .cornerRadius(16, corners: [.topLeft, .topRight]) // 상단 모서리만 둥글게 설정
            .padding(.horizontal) // 좌우 여백만 추가
            .padding(.top, 16) // 상단 여백 추가
            .frame(maxWidth: .infinity)
            .presentationDetents([.medium, .large]) // 시트 높이를 자동으로 조절
            .presentationDragIndicator(.visible) // 드래그 인디케이터 표시
            .sheet(isPresented: $showReportSheet) {
                ReportReasonSheetView(isPresented: $showReportSheet) { reason in
                    print("신고 사유: \(reason)")
                    isPresented = false
                }
                .presentationDetents([.fraction(0.5), .large]) // 시트 높이를 자동으로 조절
                .presentationDragIndicator(.visible)
            }
        }
    }
    // 신고하기 버튼을 보여줄지 결정 함수
    private func shouldShowReportButton() -> Bool {
        switch shareType {
        case let .memo(memo):
            return memo.email != authManager.email
        case let .column(column):
            return column.email != authManager.email
        }
    }
}

// UIView extension to customize which corners are rounded
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// RoundedCorner struct for customizing corner radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
//
//#Preview {
//    ShareSheetView(isPresented: .constant(true))
//}
