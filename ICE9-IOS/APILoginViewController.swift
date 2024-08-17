import UIKit

class APILoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    static var shared: APILoginViewController?
    
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        APILoginViewController.shared = self
    }
    
    func ClearLoginTextFields()
    {
        usernameTextField.text = ""
        passwordTextField.text = ""
        usernameTextField.becomeFirstResponder()
    }

    @IBAction func LoginButton_Pressed(_ sender: UIButton) 
    {
        guard let username = usernameTextField.text, let password = passwordTextField.text else
        {
            print("Please enter both username and password")
            return
        }
            
        let urlString = "https://mdev1004-m2024-api-q9bi.onrender.com/api/login"
        //let urlString = "http://localhost:3000/api/login"
        guard let url = URL(string: urlString) else
        {
            print("Invalid URL")
            return
        }
        
        // Configure the request
        let parameters = ["username": username, "password":password]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do 
        {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        }
        catch
        {
            print("Failed to encode parameters: \(error)")
            return
        }
        
        // Issue the request to the API
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error
            {
                print("Failed to send request: \(error)")
                return
            }
            
            guard let data = data else
            {
                print ("Empty response")
                return
            }
            
            // API Response
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success == true
                {
                    if let token = json?["token"] as? String
                    {
                        // Save the token in UserDefaults or other local storage
                        UserDefaults.standard.set(token, forKey: "AuthToken")
                        print("User logged in successfully")
                        
                        DispatchQueue.main.async
                        {
                            // Proceed to the MovieViewController
                            self?.performSegue(withIdentifier: "LoginSegue", sender: nil)
                        }
                    }
                    else
                    {
                        print("Token not found in the response")
                    }
                }
                else
                {
                    let errorMessage = json?["msg"] as? String ?? "Uknown error"
                    print("Login failed: \(errorMessage)")
                }
            }
            catch
            {
                print("Error decoding JSON response \(error)")
            }
        }
        task.resume()
    }
    
    @IBAction func RegisterButton_Pressed(_ sender: UIButton) 
    {
        performSegue(withIdentifier: "RegisterSegue", sender: nil)
    }
    
    @IBAction func unwindToLoginViewController(_ unwindSegue: UIStoryboardSegue)
    {
        ClearLoginTextFields()
    }
}
