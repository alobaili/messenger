//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Abdulaziz AlObaili on 21/07/2020.
//  Copyright © 2020 Abdulaziz AlObaili. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let progressHUD = JGProgressHUD(style: .dark)
    
    private var users = [Dictionary<String, [String : String]>.Element]()
    private var results = [Dictionary<String, [String : String]>.Element]()
    private var hasFetched = false
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController()
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for a user..."
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = false
        searchController.showsSearchResultsController = false
        return searchController
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        return tableView
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No results found"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.textColor = .systemGray
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        navigationItem.searchController = searchController
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            noResultsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            noResultsLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            noResultsLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            noResultsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            self.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    

}

extension NewConversationViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let firstName = results[indexPath.row].value["first_name"]!
        let lastName = results[indexPath.row].value["last_name"]!
        cell.textLabel?.text = "\(firstName) \(lastName)"
        return cell
    }
    
    
}

extension NewConversationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        results.removeAll()
        searchUsers(query: text)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        results = users
        updateUI()
    }
    
    func searchUsers(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            progressHUD.show(in: view)
            DatabaseManager.shared.getAllUsers { [unowned self] (result) in
                switch result {
                    case .success(let users):
                        self.hasFetched = true
                        self.users = users
                        self.filterUsers(with: query)
                    case .failure(let error):
                        print("Failed to get users: \(error)")
                }
            }
        }
    }
    
    func filterUsers(with term: String) {
        guard hasFetched else { return }
        
        progressHUD.dismiss()
        
        let results = users.filter { (user) -> Bool in
            let name = "\(user.value["first_name"]!.lowercased()) \(user.value["last_name"]!.lowercased())"
            
            return name.contains(term.lowercased())
        }
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            noResultsLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noResultsLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
    
    
}
