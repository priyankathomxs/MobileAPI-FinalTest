import UIKit

class AddEditAPICRUDViewController: UIViewController 
{

    // UI References
    @IBOutlet weak var AddEditTitleLabel: UILabel!
    @IBOutlet weak var UpdateButton: UIButton!
    
    // Movie Fields
    
    @IBOutlet weak var movieIDTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var studioTextField: UITextField!
    @IBOutlet weak var genresTextField: UITextField!
    @IBOutlet weak var directorsTextField: UITextField!
    @IBOutlet weak var writersTextField: UITextField!
    @IBOutlet weak var actorsTextField: UITextField!
    @IBOutlet weak var lengthTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var mpaRatingTextField: UITextField!
    @IBOutlet weak var criticsRatingTextField: UITextField!
    
    var movie: Movie?
    
    // used for MovieViewController to pass data to the AddEditAPICRUDViewController (this controller)
    var movieViewController: MovieViewController?
    var movieUpdateCallback: (()-> Void)? //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let movie = movie 
        {
            // Editing an Existing Movie
            movieIDTextField.text = movie.movieID
            titleTextField.text = movie.title
            studioTextField.text = movie.studio
            genresTextField.text = movie.genres?.joined(separator: ", ")
            directorsTextField.text = movie.directors?.joined(separator: ", ")
            writersTextField.text = movie.writers?.joined(separator: ", ")
            actorsTextField.text = movie.actors?.joined(separator: ", ")
            lengthTextField.text = "\(movie.length ?? 0)"
            yearTextField.text = "\(movie.year ?? 1900)"
            descriptionTextView.text = movie.shortDescription
            mpaRatingTextField.text = movie.mpaRating
            criticsRatingTextField.text = "\(movie.criticsRating ?? 0.0)"
            
            AddEditTitleLabel.text = "Edit Movie"
            UpdateButton.setTitle("Update", for: .normal)
        }
        else
        {
            AddEditTitleLabel.text = "Add Movie"
            UpdateButton.setTitle("Add", for: .normal)
        }

    }
    
    
    @IBAction func CancelButton_Pressed(_ sender: UIButton) 
    {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func UpdateButton_Pressed(_ sender: UIButton)
    {
        // Retrieve AuthToken
        guard let authToken = UserDefaults.standard.string(forKey: "AuthToken") else
        {
            print("AuthToken not available")
            return
        }
        
        // Configure the Request
        let urlString: String
        let requestType: String
        
        if let movie = movie {
            requestType = "PUT"
            urlString = "https://mdev1004-m2024-api-q9bi.onrender.com/api/movie/update/\(movie._id)"
            //urlString = "http://localhost:3000/api/movie/update/\(movie._id)"
        }
        else {
            requestType = "POST"
            urlString = "https://mdev1004-m2024-api-q9bi.onrender.com/api/movie/add"
            //urlString = "http://localhost:3000/api/movie/add"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        // Explicitly define the types of data
        let id: String = movie?._id ?? UUID().uuidString
        let movieID: String = movieIDTextField.text ?? ""
        let title: String = titleTextField.text ?? ""
        let studio: String = studioTextField.text ?? ""
        let genres: String = genresTextField.text ?? ""
        let directors: String = directorsTextField.text ?? ""
        let writers: String = writersTextField.text ?? ""
        let actors: String = actorsTextField.text ?? ""
        let year: Int = Int(yearTextField.text ?? "") ?? 0
        let length: Int = Int(lengthTextField.text ?? "") ?? 0
        let shortDescription: String = descriptionTextView.text ?? ""
        let mpaRating: String = mpaRatingTextField.text ?? ""
        let criticsRating: Double = Double(criticsRatingTextField.text ?? "") ?? 0.0
        
        // create the moive with the parsed data
        let movie = Movie(
            _id: id,
            movieID: movieID,
            title: title,
            studio: studio,
            genres: [genres],
            directors: [directors],
            writers: [writers],
            actors: [actors],
            year: year,
            length: length,
            shortDescription: shortDescription,
            mpaRating: mpaRating,
            criticsRating: criticsRating
        )
        
        // continue to configure the request
        var request = URLRequest(url: url)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        //Request
        do {
            request.httpBody = try JSONEncoder().encode(movie)
            
            print("Request")
            print(movie)
            
        } catch {
            print("Failed to encode movie: \(error)")
            return
        }
        
        // Response
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        
            
            if let error = error
            {
                print("Failed to send request: \(error)")
                return
            }
        
            
            DispatchQueue.main.async
            {
                self?.dismiss(animated: true)
                {
                    self?.movieUpdateCallback?()
                }
            }
        }
        
        task.resume()
        
    }
    
}
