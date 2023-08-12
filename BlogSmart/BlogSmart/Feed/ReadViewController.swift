//
//  ReadViewController.swift
//  BlogSmart
//
//  Created by Raunaq Malhotra on 4/13/23.
//

import UIKit
import ParseSwift

class ReadViewController: UIViewController {

    @IBOutlet weak var blogTable: UITableView!
    
    @IBOutlet weak var loggingButton: UIBarButtonItem!
    
    let searchController = UISearchController(searchResultsController: nil)
    private var searching = false
    
    private let refreshControl = UIRefreshControl()
    
    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            blogTable.reloadData()
        }
    }
    
    private var searchedPosts = [Post]() {
        didSet {
            blogTable.reloadData()
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Delegate table view roles
        blogTable.delegate = self
        blogTable.dataSource = self
        // blogTable.allowsSelection = false
        
        if User.current == nil {
            loggingButton.title = "Log In"
        } else {
            loggingButton.title = "Log Out"
        }
        
        blogTable.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        
        configureSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryPosts()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: Pt 1 - Pass the selected post to the detail view controller

        // Get the cell that triggered the segue
        if let cell = sender as? UITableViewCell,
           // Get the index path of the cell from the table view
           let indexPath = blogTable.indexPath(for: cell),
           // Get the detail view controller
           let detailViewController = segue.destination as? DetailViewController
        {
            
            // Use the index path to get the associated post
            var post = posts[indexPath.row]
            if searching {
                post = searchedPosts[indexPath.row]
            }
            
            // Set the post content on the detail view controller
            detailViewController.post = post
        }
    }
    
    // Configure search controller
    private func configureSearchController() {
        searchController.loadViewIfNeeded()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.enablesReturnKeyAutomatically = false
        searchController.searchBar.returnKeyType = UIReturnKeyType.default
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        searchController.searchBar.placeholder = "Search by Title"
    }
    
    private func queryPosts(completion: (() -> Void)? = nil) {
        // Create the query to fetch posts
        // Any properties that are Parse objects are stored by reference in Parse DB and as such need to explicitly use `include_:)` to be included in query results.
        // Sort the posts by descending order based on the created at date
        
        var query = Post.query()
            .order([.descending("createdAt")])
        
        if let currentUser = User.current,
           let blockedUsers = currentUser.blockedUsers {
            
            query = Post.query()
                .include("user")
                .where(notContainedIn(key: "user", array: blockedUsers))
                .order([.descending("createdAt")])
        }
        
        // Fetch posts defined in the query (asynchronously)
        query.find { [weak self] result in
            switch result {
            case .success(let posts):
                // Update local posts property with fetched posts
                self?.posts = posts
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
            // Call the completion handler (regardless of error or success, this will signal the query finished)
            // This is used to tell the pull-to-refresh control to stop refresshing
            completion?()
        }
    }
    

    @IBAction func onLogOutDidTapped(_ sender: Any) {
        if User.current != nil {
            showConfirmLogoutAlert()
        } else {
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        
    }
    
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    private func showLogInToWrite() {
        let alertController = UIAlertController(title: "Log into your account", message: "You need to log in to write and upload blogs.", preferredStyle: .alert)
        let logInAction = UIAlertAction(title: "Log In", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logInAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @objc private func onPullToRefresh() {
        refreshControl.beginRefreshing()
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    override func
    shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "writeSegue" {
            // Determine whether the segue should be performed based on our condition
            let shouldShowPopup = User.current != nil
            if !shouldShowPopup {
                showLogInToWrite()
            }
            return shouldShowPopup
        }
        // Allow other segues to proceed as usual
        return true
    }
}

extension ReadViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchedPosts.count
        } else {
            return posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        
        if searching {
            cell.configure(with: searchedPosts[indexPath.row])
        } else {
            cell.configure(with: posts[indexPath.row])
        }
        
        return cell
    }
}

extension ReadViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text!
        
        if !searchText.isEmpty {
            searching = true
            searchedPosts = []
            for myPost in posts {
                if let title = myPost.title, title.lowercased().contains(searchText.lowercased()) {
                    searchedPosts.append(myPost)
                }
            }
        }
        else {
            searching = false
            searchedPosts = posts
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchedPosts.removeAll()
        blogTable.reloadData()
    }
}
