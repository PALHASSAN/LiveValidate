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
### 1. Core & Logic Rules
| Rule | Description |
| :--- | :--- |
| **`.name(String)`** | Sets a custom attribute name (e.g., "Phone Number"). |
| **`.required()`** | Field cannot be empty. For `Bool`, it must be `true`. |
| **`.requiredIf(Bool)`** | Required only if the specific condition is true. |
| **`.match(String)`** | Ensures value matches another string (e.g., password confirmation). |
| **`.boolean()`** | Validates truthy values (`true`, `1`, `"yes"`, `"no"`). |

### 2. String & Numeric Rules
| Rule | Description |
| :--- | :--- |
| **`.min(Int) / .max(Int)`** | Enforces character length limits. |
| **`.between(Int, Int)`** | Enforces a range (e.g., `.between(4, 12)`). |
| **`.numeric() / .alpha()`** | Numbers only or Letters only. |
| **`.alphaNum() / .alphaDash()`** | Alphanumeric or Alphanumeric with dashes/underscores. |
| **`.digits(Int)`** | Exactly N digits (useful for OTP/PIN). |
| **`.integer() / .decimal()`** | Ensures the input is a valid number/decimal. |
| **`.email() / .url()`** | Validates standard Email or URL formats. |
| **`.iban()`** | Validates International Bank Account Number format (removes spaces). |
| **`.regex(Pattern)`** | Custom Regular Expression validation. |

### 3. Date Rules (Native DatePicker Support)
| Rule | Description |
| :--- | :--- |
| **`.date()`** | Validates standard ISO8601 date strings. |
| **`.dateFormat(String)`** | Validates against a custom format (e.g., "yyyy-MM-dd"). |
| **`.after(Date)`** | Ensures date is strictly after a reference date. |
| **`.before(Date)`** | Ensures date is strictly before a reference date (e.g., Birthdays). |
| **`.afterOrEqual(Date)`** | Date must be equal to or after the reference. |

---

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
    
    // Pass the projected value's error ($username)
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

### 🎨 Customizing Messages
Dynamic placeholders make your messages user-friendly:
```swift
    @Validate(.between(5, 10, "The :attribute must be between :value characters."))
    var password: String = ""
    // Result: "The Password must be between 5-10 characters."
```

### 🚀 Usage Example
```swift
import SwiftUI
import LiveValidate

struct RegisterView: View {
    // String Validation
    @Validate(.name("Username"), .required(), .min(3))
    var username: String = ""

    // Date Validation (Supports DatePicker natively)
    @Validate(.name("Birth Date"), .before(Date()))
    var birthDate: Date = Date()
    
    // Boolean Validation (Supports Toggle natively)
    @Validate(.name("Terms"), .required("You must accept the :attribute"))
    var agreed: Bool = false

    var body: some View {
       Form {
            Section("Profile") {
                TextField("Username", text: $username)
                ErrorMessage($username)
                
                // No .binding needed! Just use $
                DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)
                ErrorMessage($birthDate)
            }
            
            Section {
                Toggle("Accept Terms", isOn: $agreed)
                ErrorMessage($agreed)
            }
        }
    }
}
```
