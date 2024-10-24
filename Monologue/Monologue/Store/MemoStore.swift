//
//  MemoStore.swift
//  Monologue
//
//  Created by Hyunwoo Shin on 10/15/24.
//

import Foundation
import Observation
import FirebaseCore
import FirebaseFirestore

class MemoStore: ObservableObject {
    @Published var memos: [Memo] = []
    @Published var filterMemos: [Memo] = []
    private var memoImageStore: MemoImageStore = .init()
    
    // MARK: - 메모 전체 추가, 수정
    func addMemo(memo: Memo, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        let memoRef = db.collection("Memo").document(memo.id)
        memoRef.setData([
            "content": memo.content,
            "email": memo.email,
            "userNickname": memo.userNickname,
            "font": memo.font,
            "backgroundImageName": memo.backgroundImageName,
            "categories": memo.categories,
            "likes": memo.likes,
            "date": Timestamp(date: memo.date),
            "lineCount": memo.lineCount
        ]) { error in
            if let error = error {
                completion(error)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            if let comments = memo.comments {
                for comment in comments {
                    dispatchGroup.enter()
                    let commentRef = memoRef.collection("comments").document(comment.id)
                    commentRef.setData([
                        "content": comment.content,
                        "date": comment.date,
                        "userNickname": comment.userNickname
                    ]) { error in
                        if let error = error {
                            completion(error)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(nil) // 모든 댓글이 추가된 후 완료
            }
        }
    }
    
    func addMemo(memo: Memo) async throws {
        let db = Firestore.firestore()
        
        let memoRef = db.collection("Memo").document(memo.id)
        try await memoRef.setData([
            "content": memo.content,
            "email": memo.email,
            "userNickname": memo.userNickname,
            "font": memo.font,
            "backgroundImageName": memo.backgroundImageName,
            "categories": memo.categories,
            "likes": memo.likes,
            "date": Timestamp(date: memo.date),
            "lineCount": memo.lineCount
        ])
        
        if let comments = memo.comments {
            for comment in comments {
                let commentRef = memoRef.collection("comments").document(comment.id)
                try await commentRef.setData([
                    "content": comment.content,
                    "date": comment.date,
                    "userNickname": comment.userNickname
                ])
            }
        }
    }
    // MARK: - 닉네임 변경 시 해당 닉네임의 메모에 보관되어있는 닉네임 변경
    @MainActor
    func changeMemosNickname(email: String, newNickname: String) async throws {
        var tempMemos = try await loadMemosByUserEmail(email: email)
        
        for index in 0..<tempMemos.count {
            tempMemos[index].userNickname = newNickname
            
            try await addMemo(memo: tempMemos[index])
        }
    }    
    
    // MARK: - 메모 전체 로드
    func loadMemos(completion: @escaping ([Memo]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo").getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            var memos: [Memo] = []
            
            for document in querySnapshot!.documents {
                Task {
                    do {
                        let memo = try await Memo(document: document)
                        
                        memos.append(memo)
                        self.memos = memos
                    } catch {
                        print("loadMemos error: \(error.localizedDescription)")
                    }
                }
            }
            completion(memos, nil)
        }
    }
    
    @MainActor
    func loadMemos() async throws -> [Memo] {
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("Memo").getDocuments()
            
            var memos: [Memo] = []
            
            for document in querySnapshot.documents {                
                do {
                    let memo = try await Memo(document: document)
                    
                    memos.append(memo)
                    
                    
                } catch {
                    print("loadMemos error: \(error.localizedDescription)")
                    
                    return []
                }
            }
            
            self.memos = memos
        } catch {
            print("loadMemos error: \(error.localizedDescription)")
            
            return []
        }
        
        return memos
    }
    // MARK: - memoView refresh 시 리로드
    @MainActor
    func reloadMemos() async {
        do {
            // Firestore에서 메모를 비동기적으로 다시 로드
            let newMemos = try await loadMemos()  // 비동기 호출
            // 최신 메모 데이터를 memos 배열에 저장
            self.memos = newMemos
        } catch {
            print("Error reloading memos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 메모 아이디들로 로드 // 좋아요 관련 로직
    @MainActor
    func loadMemosByIds(ids: [String]) async throws -> [Memo] {
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("Memo")
                .whereField(FieldPath.documentID(), in: ids).getDocuments()
            
            var memos: [Memo] = []
            
            for document in querySnapshot.documents {
                do {
                    let memo = try await Memo(document: document)
                    
                    memos.append(memo)
                    
                } catch {
                    print("loadMemos error: \(error.localizedDescription)")
                    
                    return []
                }
            }
            
            self.memos = memos
        } catch {
            print("loadMemos error: \(error.localizedDescription)")
            
            return []
        }
        
        return memos
    }
    
    
    // MARK: - 메모 유저 이메일로 로드
    @MainActor
    func loadMemosByUserEmail(email: String, completion: @escaping ([Memo]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo")
            .whereField("email", isEqualTo: email)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                var memos: [Memo] = []
                
                for document in querySnapshot!.documents {
                    Task {
                        do {
                            let memo = try await Memo(document: document)
                            
                            memos.append(memo)
                            self.memos = memos
                        } catch {
                            print("loadMemosByUserEmail error: \(error.localizedDescription)")
                        }
                    }
                }
                completion(memos, nil)
            }
    }
    
    @MainActor
    func loadMemosByUserEmail(email: String) async throws -> [Memo] {
        let db = Firestore.firestore()
        
        let querySnapshot = try await db.collection("Memo")
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        var memos: [Memo] = []
        
        for document in querySnapshot.documents {
            do {
                let memo = try await Memo(document: document)
                
                memos.append(memo)
            } catch {
                print("loadMemosByUserEmail error: \(error.localizedDescription)")
            }
        }
        
        self.memos = memos

        return memos
    }
    
    // MARK: - 메모 카테고리들로 로드
    func loadMemosByCategories(categories: [String], completion: @escaping ([Memo]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo")
            .whereField("categories", arrayContains: categories[0])
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                var memos: [Memo] = []
                
                for document in querySnapshot!.documents {
                    Task {
                        do {
                            let memo = try await Memo(document: document)
                            
                            memos.append(memo)
                            self.memos = memos
                        } catch {
                            print("loadMemosByCategories error: \(error.localizedDescription)")
                        }
                    }
                }
                
                completion(memos, nil)
            }
    }
    
    @MainActor
    func loadMemosByCategories(categories: [String]) async throws -> [Memo] {
        let db = Firestore.firestore()
        
        let querySnapshot = try await db.collection("Memo")
            .whereField("categories", arrayContains: categories[0])
            .getDocuments()
        
        var memos: [Memo] = []
        
        for document in querySnapshot.documents {
            do {
                let memo = try await Memo(document: document)
                
                memos.append(memo)
            } catch {
                print("loadMemosByCategories error: \(error.localizedDescription)")
            }
        }
        
        self.memos = memos
        
        return memos
    }
    
    // MARK: - 메모 email들로 로드
    @MainActor
    func loadMemosByEmails(emails: [String]) async throws -> [Memo] {
        let db = Firestore.firestore()
        
        let querySnapshot = try await db.collection("Memo")
            .whereField("email", in: emails)
            .getDocuments()
        
        var memos: [Memo] = []
        
        for document in querySnapshot.documents {
            do {
                let memo = try await Memo(document: document)
                
                memos.append(memo)
            } catch {
                print("loadMemosByCategories error: \(error.localizedDescription)")
            }
        }
        
        self.memos = memos
        
        return memos
    }
    
    // MARK: - 메모 content로 포함 된 메모들 로드
    @MainActor
    func loadMemosByContent(content: String) async throws -> [Memo] {
        memos = try await loadMemos()
        
        var filteredMemos: [Memo] = []
        
        for memo in memos {
            if memo.content.contains(content) {
                filteredMemos.append(memo)
            }
        }
        
        self.memos = filteredMemos
        
        return self.memos
    }
    
    // MARK: - 메모 아이디로 메모 삭제
    func deleteMemo(memoId: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo").document(memoId).delete { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    @MainActor
    func deleteMemo(memoId: String) async throws {
        let db = Firestore.firestore()
        
        do {
            try await db.collection("Memo").document(memoId).delete()
            self.memoImageStore.deleteImageFromCache(imageName: memoId)
            self.memos.removeAll { $0.id == memoId }
        } catch {
            print("deleteMemo error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 좋아요 수정
    func updateLikes(memoId: String, email: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        loadMemoLikes(memoId: memoId) { likes, error in
            if let error = error {
                completion(error)
                return
            }
            
            var tempLikes: [String] = likes ?? []
            
            if tempLikes.contains(email) {
                tempLikes.remove(at: tempLikes.firstIndex(of: email)!)
            } else {
                tempLikes.append(email)
            }
            
            db.collection("Memo").document(memoId).updateData([
                "likes": tempLikes
            ]) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func loadMemoLikes(memoId: String, completion: @escaping ([String]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo").document(memoId).getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, nil)
                return
            }
            
            let likes = document.data()?["likes"] as? [String]
            completion(likes, nil)
        }
    }
    
    func updateLikes(memoId: String, email: String) async throws {
        let db = Firestore.firestore()
        
        let likes = try await loadMemoLikes(memoId: memoId)
        
        var tempLikes: [String] = likes ?? []
        
        if tempLikes.contains(email) {
            tempLikes.remove(at: tempLikes.firstIndex(of: email)!)
        } else {
            tempLikes.append(email)
        }
        
        try await db.collection("Memo").document(memoId).updateData([
            "likes": tempLikes
        ])
    }
    
    func loadMemoLikes(memoId: String) async throws -> [String]? {
        let db = Firestore.firestore()
        
        let document = try await db.collection("Memo").document(memoId).getDocument()
        
        guard let data = document.data(), document.exists else {
            return nil
        }
        
        let likes = data["likes"] as? [String]
        return likes
    }
    
    // MARK: - 댓글 수정
    func updateComment(memoId: String, email: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        loadMemoComment(memoId: memoId) { comments, error in
            if let error = error {
                completion(error)
                return
            }
            
            var tempComments: [String] = comments ?? []
            
            if tempComments.contains(email) {
                tempComments.remove(at: tempComments.firstIndex(of: email)!)
            } else {
                tempComments.append(email)
            }
            
            db.collection("Memo").document(memoId).updateData([
                "comments": tempComments
            ]) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func loadMemoComment(memoId: String, completion: @escaping ([String]?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("Memo").document(memoId).getDocument { (document, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let document = document, document.exists else {
                completion(nil, nil)
                return
            }
            
            let comments = document.data()?["comments"] as? [String]
            completion(comments, nil)
        }
    }
    
    func updateComment(memoId: String, email: String) async throws {
        let db = Firestore.firestore()
        
        let comments = try await loadMemoComment(memoId: memoId)
        
        var tempComments: [String] = comments ?? []
        
        if let index = tempComments.firstIndex(of: email) {
            tempComments.remove(at: index)
        } else {
            tempComments.append(email)
        }
        
        try await db.collection("Memo").document(memoId).updateData([
            "comments": tempComments
        ])
    }

    func loadMemoComment(memoId: String) async throws -> [String]? {
        let db = Firestore.firestore()
        
        let document = try await db.collection("Memo").document(memoId).getDocument()
        
        guard let data = document.data(), document.exists else {
            return nil
        }
        
        let comments = data["comments"] as? [String]
        return comments
    }
}
