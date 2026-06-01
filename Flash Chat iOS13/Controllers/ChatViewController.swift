//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages:[Message] = [
        Message(sender: "1@2.com", body: "Heey")
    ]
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        messageTextfield.delegate = self
        tableView.dataSource = self
        super.viewDidLoad()
        title = K.appName
        navigationItem.hidesBackButton = true
        
        loadMessages()
    }
    
    func loadMessages(){
        
        db.collection(K.FStore.collectionName).order(by:K.FStore.dateField).addSnapshotListener{ (querySnapshot, error) in
            self.messages = []
            
            if let error{
                print(error)
            }
            else {
                self.messages = []
                if let querySnapshot{
                    for document in querySnapshot.documents{
                        if let messageSender = document.data()[K.FStore.senderField] as? String,
                           let messageBody = document.data()[K.FStore.bodyField] as? String {
                            let newMesage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMesage)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let message = messageTextfield.text, let sender = Auth.auth().currentUser?.email{
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.bodyField : message,
                K.FStore.senderField : sender,
                K.FStore.dateField : Date.timeIntervalSinceReferenceDate
            ]) { err in
                if let err{
                    print(err.localizedDescription)
                }
                else{
                    DispatchQueue.main.async{
                        self.messageTextfield.text = ""
                    }
                    print("TExxt")
                }
            }
        }
    }
    
    @IBAction func logOutButton(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError.localizedDescription)
        }
    }
    
}

extension ChatViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.body
        
        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        else{
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lighBlue)
            cell.label.textColor = UIColor(named: K.BrandColors.blue)
        }
        
        return cell
    }
}


extension ChatViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendPressed(sendButton)
        return true
    }
}
