import UIKit

class ArtworkViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
        
    var artworks: [Artwork] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        fetchArtworks { [weak self] artworks, error in
            DispatchQueue.main.async
            {
                if let artworks = artworks
                {
                    if artworks.isEmpty
                    {
                        // Display a message for no data
                        self?.displayErrorMessage("No artworks available.")
                    } else {
                        self?.artworks = artworks
                        self?.tableView.reloadData()
                    }
                } else if let error = error {
                    if let urlError = error as? URLError, urlError.code == .timedOut
                    {
                        // Handle timeout error
                        self?.displayErrorMessage("Request timed out.")
                    } else {
                        // Handle other errors
                        self?.displayErrorMessage(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func displayErrorMessage(_ message: String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchArtworks(completion: @escaping ([Artwork]?, Error?) -> Void)
    {
        // Retrieve Authtoken from UserDefaults
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available")
            completion(nil, nil)
            return
        }
        
        // Configure the Request
        guard let url = URL(string: "https://mdev1004-m2024-api-q9bi.onrender.com/api/movie/list") else
        //guard let url = URL(string: "http://localhost:3000/api/artwork/list") else
        {
            print("URL Error")
            completion(nil, nil) // Handle URL error
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Issue the Request
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Network Error")
                completion(nil, error) // Handle network error
                return
            }

            guard let data = data else {
                print("Empty Response")
                completion(nil, nil) // Handle empty response
                return
            }
            
            // Response
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success == true
                {
                    if let artworksData = json?["data"] as? [[String: Any]]
                    {
                        let artworks = try JSONSerialization.data(withJSONObject: artworksData, options: [])
                        let decodedArtworks = try JSONDecoder().decode([Artwork].self, from: artworks)
                        completion(decodedArtworks, nil) // success
                    }
                    else
                    {
                        print("Missing 'data' field in JSON response")
                        completion(nil, nil) // Handle missing data field
                    }
                }
                else
                {
                    print("API Request unsuccessful")
                    let errorMessage = json?["msg"] as? String ?? "Uknown Error"
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    completion(nil, error)
                }
                
            } catch {
                print("Error Decoding JSON Data")
                completion(nil, error) // Handle JSON decoding error
            }
        }.resume()
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return artworks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtworkCell", for: indexPath) as! ArtworkTableViewCell
                        
                
        let artwork = artworks[indexPath.row]
                        
        cell.titleLabel?.text = artwork.title
        cell.artistLabel?.text = artwork.artist
        cell.yearCreatedLabel?.text = "\(artwork.yearCreated ?? 0000 )"
                
        // Set the background color of curren Location Label based on the yearCreated
        let yearCreated = artwork.yearCreated


        if let yearCreated = yearCreated{
            if yearCreated > 1000 {
                cell.yearCreatedLabel.backgroundColor = UIColor.green
                cell.yearCreatedLabel.textColor = UIColor.black
            } else if  yearCreated < 100 {
                cell.yearCreatedLabel.backgroundColor = UIColor.yellow
                cell.yearCreatedLabel.textColor = UIColor.black
            } else {
                cell.yearCreatedLabel.backgroundColor = UIColor.red
                cell.yearCreatedLabel.textColor = UIColor.white
            }
        } else {
            // Handle the case where rating is nil, if needed
            cell.yearCreatedLabel.backgroundColor = UIColor.gray
            cell.yearCreatedLabel.textColor = UIColor.white
            cell.yearCreatedLabel.text = "N/A"
        }
        
        
        return cell
    }
    
    // New for ICE8
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) 
    {
        performSegue(withIdentifier: "AddEditSegue", sender: indexPath)
    }
    
    // Swipe Left Gesture
    func tableView(_ tableView: UITableView, commit editingSytle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if(editingSytle == .delete)
        {
            let artwork = artworks[indexPath.row]
            ShowDeleteConfirmationAlert(for: artwork) { confirmed in
                if(confirmed)
                {
                    // delete artwork
                    self.deleteArtwork(at: indexPath)
                }
            }
        }
    }
    
    func ShowDeleteConfirmationAlert(for artwork: Artwork, completion: @escaping (Bool) -> Void)
    {
        let alert = UIAlertController(title: "Delete Artwork", message: "Are you sure you want to delete this artwork?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteArtwork(at indexPath: IndexPath)
    {
        let artwork = artworks[indexPath.row]
        
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available")
            return
        }
        
        guard let url = URL(string: "https://mdev1004-m2024-api-q9bi.onrender.com/api/movie/delete/\(artwork._id)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Failed to delete artwork: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.artworks.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
        }
        
        task.resume()
    }
    
    
    @IBAction func AddButton_Pressed(_ sender: UIButton) {
        performSegue(withIdentifier: "AddEditSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "AddEditSegue"
        {
            if let AddEditVC = segue.destination as? AddEditAPICRUDViewController
            {
                AddEditVC.artworkViewController = self
                if let indexPath = sender as? IndexPath
                {
                    // Editing an existing artwork
                    let artwork = artworks[indexPath.row]
                    AddEditVC.artwork = artwork
                } else {
                    // Adding a new Artwork
                    AddEditVC.artwork = nil
                }
                
                // Set the callback closure to reload artworks
                AddEditVC.artworkUpdateCallback = { [weak self] in
                    self?.fetchArtworks { artworks, error in
                        if let artworks = artworks {
                            self?.artworks = artworks
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        else if let error = error
                        {
                            print("Failed to fetch artworks: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func logoutButton_Pressed(_ sender: UIButton) 
    {
        // Remove the token from UserDefaults or local storage -> indicates a logout
        UserDefaults.standard.removeObject(forKey: "AuthToken")
        
        // Clear the username and password in the LoginViewController
        APILoginViewController.shared?.ClearLoginTextFields()
        
        // unwind
        performSegue(withIdentifier: "unwindToLogin", sender: self)
    }
    
}
