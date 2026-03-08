## 📖 Introduction
**LiveValidate** is a lightweight, declarative validation framework for SwiftUI. It enables real-time feedback for user inputs and integrates seamlessly with backend APIs and local SwiftData storage.

### 📦 Installation
Add the package to your project via **Swift Package Manager (SPM)**:
In Xcode: `File > Add Package Dependencies...` and enter this URL in the search bar:

```
https://github.com/PALHASSAN/LiveValidate.git
```

## ✨ Features
* **Real-time Validation:** Instant feedback as the user types.
* **Smart Debouncing:** Prevents UI lag and excessive server hits.
* **Dual-Engine Support:** Switch between **Remote API** and **Local SwiftData** effortlessly.
* **Built-in UI Components:** Includes `ErrorMessage` with built-in shake animations.
* **Strongly Typed:** Leverages Swift KeyPaths for safe database queries.

## 🛠 Supported Rules
| Rule | Description |
| :--- | :--- |
| **`.name(String)`** | (Optional) Sets a custom attribute name for error messages. If not provided, it defaults to "field". |
| **`.required()`** | Field cannot be empty or null. |
| **`.email()`** | Validates standard email format. |
| **`.unique(table: "", column: "")`** | Remote check via API POST request (Server-side). |
| **`.unique(model: "", field: "")`** | Local check via **SwiftData** KeyPath (On-device). |
| **`.min(Int) / .max(Int)`** | Enforces minimum or maximum character length. |
| **`.numeric() / .alpha()`** | Restricts input to numbers only or letters only. |
| **`.alphaNum()`** | Allows only letters and numbers. |
| **`.alphaDash()`** | Allows letters, numbers, dashes, and underscores. |
| **`.digits(Int)`** | Requires a specific number of digits (e.g., OTP or Pin). |
| **`.match(String)`** | Ensures the value matches another field (e.g., Password Confirmation). |
| **`.regex(Pattern)`** | Validates against a custom Regular Expression. |
| **`.url()`** | Validates URL format. |
| **`.inList([String])`** | Restricts input to a specific predefined list of values. |

## 🚀 Setup & Usage
### 1. Global Configuration
Before using rules like .unique, you must initialize the validation engine once at the start of your app (e.g., in your App struct or within a Preview). This tells the package where to verify data uniqueness.

#### **Option A: Remote API (Laravel/Nestjs/etc.)**
Use this if you want to check uniqueness against a remote server. The package will send a POST request with a JSON body.
```swift
ValidateConfig.setup(engine: .api(url: "https://api.example.com/"))
```

#### **Option B: Local SwiftData**
Use this if you are using Apple's SwiftData and want to check for unique records locally on the device.
```swift
ValidateConfig.setup(engine: .swiftData(container: sharedModelContainer)))
```

### 2. Property Validation & UI Integration
To validate a field, apply the @Validate property wrapper to your @State variables. You can then bind these variables to standard SwiftUI components like TextField or SecureField.

#### **A: Define Rules**
List the rules you want to apply in the order they should be checked:
```swift
@Validate(.name("Username"), .required(), .min(3), .unique(model: User.self, field: \.username))
var username: String = ""
```

#### **B: Display Errors**
Use the built-in ErrorMessage view to display validation errors automatically. It includes a built-in shake animation that triggers whenever a new error appears.
```swift
VStack(alignment: .leading) {
    TextField("Username", text: $username)
    
    // Pass the projected value's error ($username.error)
    ErrorMessage($username) 
}
```

### 3. Property Validation & UI Integration
> [!NOTE]
> Sometimes you need to trigger validation manually, such as when the user clicks a "Submit" button, to ensure all fields are valid before proceeding. By default, LiveValidate handles checks in real-time, but these static methods allow you to guard final submission logic.

#### **A: validateOnly**
If you need to verify a specific group of fields—such as a single section of a multi-step form—use the .validateOnly(_:) method. You must pass the projected values (the ones prefixed with $).
```swift
Button("Login") {
    Task {
        // Triggers validation for specific fields manually
        let isValid = await Validate.validateOnly($email, $password, etc..)
        
        if isValid {
            // Proceed with login logic
        }
    }
}
```

#### **B: validateAll**
For a complete form check before final submission, use the .validateAll(_:) method to ensure every defined @Validate field in your view meets its criteria.
```swift
Button("Register") {
    Task {
        // validateAll() checks every @Validate field in the current View
        if await validateAll() {
            print("Form is valid and ready for submission!")
        }
    }
}
```

### 🚀 Usage Example
```swift
import SwiftUI
import LiveValidate

struct RegisterView: View {
    @Validate(.name("Email"), .required(), .email(), .unique(table: "users", column: "email"))
    var email: String = ""

    var body: some View {
        Form {
            TextField("Email Address", text: $email)
            ErrorMessage($email) // Built-in UI component
        }
    }
}
```
