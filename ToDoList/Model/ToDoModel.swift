//
//  RealmManager.swift
//  ToDoList
//
//  Created by 土橋正晴 on 2018/09/26.
//  Copyright © 2018 m.dobashi. All rights reserved.
//

import Foundation
import RealmSwift

class ToDoModel:Object {
    
    @objc dynamic var id:String = ""
    
    /// Todoの期限
    @objc dynamic var todoDate:String?
    
    /// Todoのタイトル
    @objc dynamic var toDoName:String = ""
    
    /// Todoの詳細
    @objc dynamic var toDo:String = ""
    
    /// Todoの作成日時
    @objc dynamic var createTime:String?
    
    
    // idをプライマリキーに設定
    override static func primaryKey() -> String? {
        return "createTime"
    }
    
    
    /// Realmのインスタンス化
    class func initRealm(_ vc: UIViewController) -> Realm? {
        
        let realm: Realm
        do {
            realm = try Realm()
            
            return realm
        }
        catch {
            AlertManager().alertAction(vc, message: "エラーが発生しました") { _ in
                                        return
            }
        }
        
        return nil
    }
    
    
    /// ToDoを追加する
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - addValue: 登録するTodoの値
    class func addRealm(_ vc: UIViewController, addValue:TableValue) {
        
        guard let realm = initRealm(vc) else { return }
        let toDoModel: ToDoModel = ToDoModel()
        
        toDoModel.id = addValue.id
        toDoModel.toDoName = addValue.title
        toDoModel.todoDate = addValue.date
        toDoModel.toDo = addValue.detail
        toDoModel.createTime = Format().stringFromDate(date: Date(), addSec: true)
        
        do {
            try realm.write() {
                realm.add(toDoModel)
            }
            ToDoModel.addNotification(toDoModel: toDoModel)
            
        }
        catch {
            AlertManager().alertAction(vc, message: "ToDoの登録に失敗しました") { _ in
                                        return
            }
        }
    
    }
    
    
    /// ToDoの更新
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - updateValue: 更新する値
    class func updateRealm(_ vc: UIViewController, todoId: Int, updateValue: TableValue) {
        guard let realm = initRealm(vc) else { return }
        let toDoModel: ToDoModel = (realm.objects(ToDoModel.self).filter("id == '\(String(describing: todoId))'").first!)
        
        do {
            try realm.write() {
                toDoModel.toDoName = updateValue.title
                toDoModel.todoDate = updateValue.date
                toDoModel.toDo = updateValue.detail
            }
            
            ToDoModel.addNotification(toDoModel: toDoModel)
            
        }
        catch {
            AlertManager().alertAction(vc,
                                       message: "ToDoの更新に失敗しました") { _ in
                                        return
            }
        }
        
    }
    
    
    /// １件取得
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - createTime: Todoの作成時間
    /// - Returns: 取得したTodoの最初の1件を返す
    class func findRealm(_ vc: UIViewController, todoId: Int, createTime: String?) -> ToDoModel? {
        guard let realm = initRealm(vc) else { return nil }
        
        if let _createTime = createTime {
            return (realm.objects(ToDoModel.self).filter("createTime == '\(String(describing: _createTime))'").first)
        } else {
            return(realm.objects(ToDoModel.self).filter("id == '\(String(describing: todoId))'").first!)
        }
        
        
    }
    
    
    /// 全件取得
    /// - Parameter vc: 呼び出し元のViewController
    /// - Returns: 取得したTodoを全件返す
    class func allFindRealm(_ vc: UIViewController) -> Results<ToDoModel>? {
        guard let realm = initRealm(vc) else { return nil }
        
        return realm.objects(ToDoModel.self)
    }
    
    
    /// ToDoの削除
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - todoId: TodoId
    ///   - createTime: Todoの作成時間
    ///   - completion: 削除完了後の動作
    class func deleteRealm(_ vc: UIViewController, todoId: Int, createTime: String?, completion: () ->Void) {
        guard let realm = initRealm(vc) else { return }
        let toDoModel: ToDoModel = (realm.objects(ToDoModel.self).filter("id == '\(String(describing: todoId))'").first!)
        
        UNUserNotificationCenter
            .current()
            .removePendingNotificationRequests(withIdentifiers: [toDoModel.createTime!])
        
        do {
            try realm.write() {
                realm.delete(toDoModel)
            }
        }
            
        catch {
            AlertManager().alertAction(vc,
                                       message: "ToDoの削除に失敗しました") { _ in
                                        return
            }
        }
        
        
        completion()
    }
    
    
    /// 全件削除
    /// - Parameters:
    ///   - vc: 呼び出し元のViewController
    ///   - completion: 削除完了後の動作
    class func allDeleteRealm(_ vc: UIViewController, completion:@escaping () ->Void) {
        guard let realm = initRealm(vc) else { return }
        
        AlertManager().alertAction(vc, title: "データベースの削除", message: "作成した問題や履歴を全件削除します", handler1: { (action) in
            try! realm.write {
                realm.deleteAll()
            }
            completion()

        }) { (action) in return }
        
    }
    
    
    class func allDelete() {

        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    
    
    
    // MARK: Set Notification
    
    /// 通知を設定する
    private class func addNotification(toDoModel: ToDoModel) {
        
        let content:UNMutableNotificationContent = UNMutableNotificationContent()
        
        content.title = toDoModel.toDoName
        
        content.body = toDoModel.toDo
        
        content.sound = UNNotificationSound.default
        
        
        //通知する日付を設定
        guard let date:Date = Format().dateFromString(string: toDoModel.todoDate!) else {
            print("期限の登録に失敗しました")
            return
        }
        
        let calendar = Calendar.current
        let dateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute] , from: date)
        
        
        let trigger:UNCalendarNotificationTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: false)
        
        let request:UNNotificationRequest = UNNotificationRequest.init(identifier: toDoModel.createTime!, content: content, trigger: trigger)
        
        let center:UNUserNotificationCenter = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            
        }
        
    }
    
}
