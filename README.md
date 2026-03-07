## 📖 Introduction
**LiveValidate** is a lightweight, declarative validation framework for SwiftUI. It enables real-time feedback for user inputs and integrates seamlessly with backend APIs and local SwiftData storage.

### 📦 Installation
Add the package to your project via **Swift Package Manager (SPM)**:
In Xcode: `File > Add Package Dependencies...` and enter this URL in the search bar:

```
https://github.com/alhassan/LiveValidate
```

## ✨ Features
* **Real-time Validation:** Instant feedback as the user types.
* **Debounced Execution:** Prevents UI lag and excessive server hits.
* **Dual-Engine Support:** Switch between **Remote API** and **Local SwiftData** effortlessly.
* **Custom UI Components:** Includes `ErrorMessage` with built-in shake animations.
* **Strongly Typed:** Leverages Swift KeyPaths for safe database queries.

## 🛠 Supported Rules
| Rule | Description |
| :--- | :--- |
| **`.name(String)`** | Set a custom attribute name for user-friendly error messages. (NOT required) |
| **`.required()`** | Field cannot be empty or null. |
| **`.email()`** | Validates standard email format. |
| **`.unique(table: "table_name" column: "column_name")`** | Remote check via API POST request (Server-side). |
| **`.unique(model:field:)`** | Local check via **SwiftData** KeyPath (On-device). |
| **`.min(Int) / .max(Int)`** | Enforces minimum or maximum character length. |
| **`.numeric() / .alpha()`** | Restricts input to numbers only or letters only. |
| **`.digits(Int)`** | Requires a specific number of digits (e.g., OTP or Pin). |
| **`.match(String)`** | Ensures the value matches another field (e.g., Password Confirm). |
| **`.regex(Pattern)`** | Validates against a custom Regular Expression. |

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
            ErrorMessage($email.error) // Built-in UI component
        }
    }
}

## 🚀 Setup & Usage

### 1. Global Configuration
Initialize the validation engine in your `App` entry point or `Preview` to enable uniqueness checks:

#### **Option A: Remote API Engine**
```swift
ValidateConfig.setup(engine: .api(url: "http://yourapilink/"))

#### **Option B: SwiftData**
```swift
ValidateConfig.setup(engine: .swiftData(container: yourSwiftData)))
