import UIKit

class MovieViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
        
    var movies: [Movie] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        fetchMovies { [weak self] movies, error in
            DispatchQueue.main.async
            {
                if let movies = movies
                {
                    if movies.isEmpty
                    {
                        // Display a message for no data
                        self?.displayErrorMessage("No movies available.")
                    } else {
                        self?.movies = movies
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
    
    func fetchMovies(completion: @escaping ([Movie]?, Error?) -> Void)
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
        //guard let url = URL(string: "http://localhost:3000/api/movie/list") else
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
                    if let moviesData = json?["data"] as? [[String: Any]]
                    {
                        let movies = try JSONSerialization.data(withJSONObject: moviesData, options: [])
                        let decodedMovies = try JSONDecoder().decode([Movie].self, from: movies)
                        completion(decodedMovies, nil) // success
                    }
                    else
                    {
                        print("Missing 'data' field in JSON response")
                        completion(nil, nil) // Handle missing data field
                    }
                }
                else
                {
                    print("API Rrequet unsuccessful")
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
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieTableViewCell
                        
                
        let movie = movies[indexPath.row]
                        
        cell.titleLabel?.text = movie.title
        cell.studioLabel?.text = movie.studio
        cell.ratingLabel?.text = "\(movie.criticsRating ?? 0.0)"
                
        // Set the background color of criticsRatingLabel based on the rating
        let rating = movie.criticsRating


        if let rating = rating {
            if rating > 7 {
                cell.ratingLabel.backgroundColor = UIColor.green
                cell.ratingLabel.textColor = UIColor.black
            } else if rating > 5 {
                cell.ratingLabel.backgroundColor = UIColor.yellow
                cell.ratingLabel.textColor = UIColor.black
            } else {
                cell.ratingLabel.backgroundColor = UIColor.red
                cell.ratingLabel.textColor = UIColor.white
            }
        } else {
            // Handle the case where rating is nil, if needed
            cell.ratingLabel.backgroundColor = UIColor.gray
            cell.ratingLabel.textColor = UIColor.white
            cell.ratingLabel.text = "N/A"
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
            let movie = movies[indexPath.row]
            ShowDeleteConfirmationAlert(for: movie) { confirmed in
                if(confirmed)
                {
                    // delete movie
                    self.deleteMovie(at: indexPath)
                }
            }
        }
    }
    
    func ShowDeleteConfirmationAlert(for movie: Movie, completion: @escaping (Bool) -> Void)
    {
        let alert = UIAlertController(title: "Delete Movie", message: "Are you sure you want to delete this movie?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        })
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        })
        
        present(alert, animated: true, completion: nil)
    }
    
    func deleteMovie(at indexPath: IndexPath)
    {
        let movie = movies[indexPath.row]
        
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available")
            return
        }
        
        guard let url = URL(string: "https://mdev1004-m2024-api-q9bi.onrender.com/api/movie/delete/\(movie._id)") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Failed to delete movie: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self?.movies.remove(at: indexPath.row)
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
                AddEditVC.movieViewController = self
                if let indexPath = sender as? IndexPath
                {
                    // Editing an existing movie
                    let movie = movies[indexPath.row]
                    AddEditVC.movie = movie
                } else {
                    // Adding a new Movie
                    AddEditVC.movie = nil
                }
                
                // Set the callback closure to reload movies
                AddEditVC.movieUpdateCallback = { [weak self] in
                    self?.fetchMovies { movies, error in
                        if let movies = movies {
                            self?.movies = movies
                            DispatchQueue.main.async {
                                self?.tableView.reloadData()
                            }
                        }
                        else if let error = error
                        {
                            print("Failed to fetch movies: \(error)")
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
