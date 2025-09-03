# Resilient Networking (SwiftUI)

This project demonstrates a **resilient networking layer** in Swift for iOS, built with **SwiftUI** for the demo UI.  
It showcases retries, exponential backoff with jitter, idempotency for safe POST retries, and request deduplication for in-flight requests.

## ✨ Features
- **Async/await HTTP client** wrapping `URLSession`
- **RetryPolicy** with exponential backoff + jitter
- **Idempotency-Key** support for POST requests
- **Request Deduplication** (multiple identical requests share one network call)
- **Pluggable Logger** for console + UI logs
- **SwiftUI Demo App** with buttons to trigger GET and POST flows

## 📱 Screenshots

### Home Screen
<img src="Home.png" width="300">

### Deduped GET Request
<img src="GET.png" width="300">

### Successful POST Request
<img src="POST-201.png" width="300">

### POST with Network Error + Retry
<img src="POST-Error.png" width="300">

## 🚀 How It Works

1. **GET /todos/1 (deduped)**  
   Fires 3 concurrent identical GET requests.  
   The `RequestDeduper` ensures only **one actual network hit** occurs.  
   All callers share the same result.

2. **POST /todos (retry+idempotent)**  
   Sends a POST with a generated **Idempotency-Key** header.  
   If a transient error occurs (5xx, 408, 429, or network offline), the client retries with exponential backoff.  
   The server sees all retries as **one logical request**.

3. Logs are shown both in **Xcode console** and inside the SwiftUI UI via a `TextEditor`.

## 🛠️ Tech Stack
- Swift 5.x / iOS 18.2+
- SwiftUI for demo UI
- Async/Await concurrency
- Protocol-oriented design (`RetryPolicy`, `HTTPLogger`)
- Actor-based deduplication

## 🧪 Example Logs

