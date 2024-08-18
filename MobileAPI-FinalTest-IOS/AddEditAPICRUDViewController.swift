import UIKit

class AddEditAPICRUDViewController: UIViewController 
{

    // UI References
    @IBOutlet weak var AddEditTitleLabel: UILabel!
    @IBOutlet weak var UpdateButton: UIButton!
    
    // Movie Fields
    
    @IBOutlet weak var artworkIDTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var mediumTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var yearCreatedTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var dimensionsTextField: UITextField!
    @IBOutlet weak var imageURLTextField: UITextField!
    @IBOutlet weak var styleTextView: UITextView!
    @IBOutlet weak var currentLocationTextField: UITextField!
    
    var artwork: Artwork?
    
    // used for ArtworkViewController to pass data to the AddEditAPICRUDViewController (this controller)
    var artworkViewController: ArtworkViewController?
    var artworkUpdateCallback: (()-> Void)? //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let artwork = artwork
        {
            // Editing an Existing Artwork
            artworkIDTextField.text = artwork.artworkID
            titleTextField.text = artwork.title
            artistTextField.text = artwork.artist
            mediumTextField.text = artwork.medium
            subjectTextField.text = artwork.subject?.joined(separator: ", ")
            yearCreatedTextField.text = "\(artwork.yearCreated ?? 1000)"
            descriptionTextField.text = artwork.description
            dimensionsTextField.text = "\(artwork.dimensions ?? 0x0)"
            imageURLTextField.text = artwork.imageURL
            styleTextView.text = artwork.style?.joined(separator: ", ")
            currentLocationTextField.text = artwork.currentLocation
            
            
            AddEditTitleLabel.text = "Edit Artwork"
            UpdateButton.setTitle("Update", for: .normal)
        }
        else
        {
            AddEditTitleLabel.text = "Add Artwork"
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
        
        if let artwork = artwork {
            requestType = "PUT"
            urlString = "https://mdev1004-m2024-api-q9bi.onrender.com/api/artwork/update/\(artwork._id)"
            //urlString = "http://localhost:3000/api/artwork/update/\(artwork._id)"
        }
        else {
            requestType = "POST"
            urlString = "https://mdev1004-m2024-api-q9bi.onrender.com/api/artwork/add"
            //urlString = "http://localhost:3000/api/artwork/add"
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL.")
            return
        }
        
        // Explicitly define the types of data
        let id: String = artwork?._id ?? UUID().uuidString
        let artworkID: String = artworkIDTextField.text ?? ""
        let title: String = titleTextField.text ?? ""
        let artist: String = artistTextField.text ?? ""
        let medium: String = mediumTextField.text ?? ""
        let subject: String = subjectTextField.text ?? ""
        let yearCreated: Int = Int(yearCreatedTextField.text ?? "") ?? 0
        let description: String = descriptionTextField.text ?? ""
        let dimensions: Int = Int(dimensionsTextField.text ?? "") ?? 0x0
        let imageURL: String = imageURLTextField.text ?? ""
        let style: String = styleTextView.text ?? ""
        let currentLocation: String = currentLocationTextField.text ?? ""
        
        
        // create the artwork with the parsed data
        let artwork = Artwork(
            _id: id,
            artworkID: artworkID,
            title: title,
            artist: artist,
            medium: medium,
            subject: [subject],
            yearCreated: yearCreated,
            description: description,
            dimensions: dimensions,
            imageURL: imageURL,
            style: [style],
            currentLocation: currentLocation
        )
        
        // continue to configure the request
        var request = URLRequest(url: url)
        request.httpMethod = requestType
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        //Request
        do {
            request.httpBody = try JSONEncoder().encode(artwork)
            
            print("Request")
            print(artwork)
            }
        catch {
            print("Failed to encode artwork: \(error)")
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
                    self?.artworkUpdateCallback?()
                }
            }
        }
        
        task.resume()
        
    }
    
}
