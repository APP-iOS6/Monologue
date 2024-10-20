//
//  UserInfoStore.swift
//  Monologue
//
//  Created by 김종혁 on 10/15/24.
//

import Foundation
import Observation
import FirebaseCore
import FirebaseFirestore
import SwiftUICore

@MainActor
class UserInfoStore: ObservableObject {
    private var memoStore: MemoStore = .init()
    private var columnStore: ColumnStore = .init()
    @Published var userInfo: UserInfo? = nil
    
    @Published var followers: [UserInfo] = []
    @Published var followings: [UserInfo] = []
    
    @Published var memoCount: [String: Int] = [:] // 닉네임별 메모 개수 저장
    @Published var columnCount: [String: Int] = [:] // 닉네임별 칼럼 개수 저장
    
    // 로그인 시 사용자(닉네임, 가입날짜) 파베에 추가
    func addUserInfo(_ user: UserInfo) async {
        do {
            let db = Firestore.firestore()
            
            try await db.collection("User").document(user.email).setData([
                "uid": user.uid,
                "nickname": user.nickname,
                "registrationDate": Timestamp(date: user.registrationDate),
                "preferredCategories": user.preferredCategories,
                "profileImageName": user.profileImageName,
                "introduction": user.introduction,
                "followings": user.followings,
                "followers": user.followers,
                "blocked": user.blocked,
                "likes": user.likes
            ])
            
            print("Document successfully written!")
        } catch {
            print("Error writing document: \(error)")
        }
    }
    
    // 사용자 정보 업데이트 (registrationDate는 업데이트되지 않음)
    func updateUserInfo(_ user: UserInfo) async {
        do {
            let db = Firestore.firestore()
            
            try await db.collection("User").document(user.email).setData([
                "uid": user.uid,
                "nickname": user.nickname,
                "preferredCategories": user.preferredCategories,
                "profileImageName": user.profileImageName,
                "introduction": user.introduction,
                "followings": user.followings,
                "followers": user.followers,
                "blocked": user.blocked,
                "likes": user.likes
            ])
            
            print("Document successfully updated!")
        } catch {
            print("Error updating document: \(error)")
        }
    }
    
    // 로드하는 부분
    func loadUserInfo(email: String) async {
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("User").document(email).getDocument()
            
            guard let docData = document.data() else {
                print("No user data found for email: \(email)")
                return
            }
            
            let uid: String = docData["uid"] as? String ?? ""
            let nickname: String = docData["nickname"] as? String ?? ""
            let registrationDate: Date = (docData["registrationDate"] as? Timestamp)?.dateValue() ?? Date()
            let preferredCategories: [String] = docData["preferredCategories"] as? [String] ?? []
            let profileImageName: String = docData["profileImageName"] as? String ?? ""
            let introduction: String = docData["introduction"] as? String ?? ""
            let followings: [String] = docData["followings"] as? [String] ?? []
            let followers: [String] = docData["followers"] as? [String] ?? []
            let blocked: [String] = docData["blocked"] as? [String] ?? []
            let likes: [String] = docData["likes"] as? [String] ?? []
            
            // `userInfoStore` 업데이트
            self.userInfo = UserInfo(
                uid: uid,
                email: email,
                nickname: nickname,
                registrationDate: registrationDate,
                preferredCategories: preferredCategories,
                profileImageName: profileImageName,
                introduction: introduction,
                followers: followers,
                followings: followings,
                blocked: blocked,
                likes: likes
            )
//            print("User info loaded successfully: \(String(describing: userInfo))")
            
        } catch {
            print("Error loading user info: \(error)")
        }
    }
    
    // 이메일에 따른 유저들의 정보를 배열로 불러오는 함수(유저 목록에 사용)
    func loadUsersInfoByEmail(emails: [String]) async throws -> [UserInfo] {
        guard !emails.isEmpty else {
            return []
        }
        
        let db = Firestore.firestore()
        
        let querySnapshot = try await db.collection("User")
            .whereField(FieldPath.documentID(), in: emails) // 배열로 변경
            .getDocuments()
        
        var usersInfo: [UserInfo] = []
        
        for document in querySnapshot.documents {
            let userInfo = UserInfo(document: document)
            usersInfo.append(userInfo)
        }
        
        return usersInfo
    }
    
    // 메모 개수
    func getMemoCount(email: String) async throws -> Int {
        let memos = try await memoStore.loadMemosByUserEmail(email: email)
        return memos.count
    }
    
    // 칼럼 개수
    func getColumnCount(email: String) async throws -> Int {
        let columns = try await columnStore.loadColumnsByUserEmail(email: email)
        return columns.count
    }
    
    // MARK: - Follow 관련 로직
    // 팔로우 로직
    func followUser(targetUserEmail: String) async {
        guard let currentUserEmail = userInfo?.email, !currentUserEmail.isEmpty else {
            print("Current user email is empty.")
            return
        }
        guard !targetUserEmail.isEmpty else {
            print("Target user email is empty.")
            return
        }

        let db = Firestore.firestore()
        let currentUserRef = db.collection("User").document(currentUserEmail)
        let targetUserRef = db.collection("User").document(targetUserEmail)

        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                // 현재 유저의 followings에 타겟 유저 추가
                transaction.updateData([
                    "followings": FieldValue.arrayUnion([targetUserEmail])
                ], forDocument: currentUserRef)
                
                // 타겟 유저의 followers에 현재 유저 추가
                transaction.updateData([
                    "followers": FieldValue.arrayUnion([currentUserEmail])
                ], forDocument: targetUserRef)

                return nil
            }

            print("Successfully followed \(targetUserEmail)")
        } catch {
            print("Error following user: \(error)")
        }
    }
    
    // 언팔로우 로직
    func unfollowUser(targetUserEmail: String) async {
        guard let currentUserEmail = userInfo?.email, !currentUserEmail.isEmpty else {
            print("Current user email is empty.")
            return
        }
        guard !targetUserEmail.isEmpty else {
            print("Target user email is empty.")
            return
        }

        let db = Firestore.firestore()
        let currentUserRef = db.collection("User").document(currentUserEmail)
        let targetUserRef = db.collection("User").document(targetUserEmail)

        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                // 현재 유저의 followings에서 타겟 유저 제거
                transaction.updateData([
                    "followings": FieldValue.arrayRemove([targetUserEmail])
                ], forDocument: currentUserRef)
                
                // 타겟 유저의 followers에서 현재 유저 제거
                transaction.updateData([
                    "followers": FieldValue.arrayRemove([currentUserEmail])
                ], forDocument: targetUserRef)

                return nil
            }

            print("Successfully unfollowed \(targetUserEmail)")
        } catch {
            print("Error unfollowing user: \(error)")
        }
    }
    
    // 특정 유저를 팔로우하고 있는지 확인
    func checkIfFollowing(targetUserEmail: String) -> Bool {
        guard let currentUser = userInfo else {
            return false
        }
        
        return currentUser.followings.contains(targetUserEmail)
    }
}
