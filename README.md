<div align="center">
  <img src="assets/images/app_icon.png" width="120" alt="ShopWave Logo">
  <h1>ShopWave</h1>
  <p><strong>A Full-Stack Flutter E-Commerce Application</strong></p>

  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter" alt="Flutter"></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart" alt="Dart"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28.svg?logo=firebase" alt="Firebase"></a>
    <a href="https://stripe.com/"><img src="https://img.shields.io/badge/Stripe-Payments-6772E5.svg?logo=stripe" alt="Stripe"></a>
    <a href="https://bloclibrary.dev/#/"><img src="https://img.shields.io/badge/State_Management-BLoC-13112E.svg?logo=dart" alt="BLoC"></a>
  </p>
</div>

---

## 📱 About ShopWave

ShopWave is a premium, fully-functional e-commerce mobile application built with Flutter. It features a modern, fluid user interface with a robust backend powered by Firebase and secure payment processing via Stripe.

Whether you're looking for inspiration for your next Flutter project, or a template to build a real-world store, ShopWave provides a production-ready architecture using the BLoC pattern, clean UI/UX, and extensive features.

## ✨ Features

- **Auth & Onboarding:** Email/Password, Google Sign-in, Apple Sign-in, and Guest mode.
- **Dynamic Storefront:** Featured products banner, categories, and horizontal/vertical scrolling lists.
- **Product Details:** High-quality image carousels, size & color selection, and customer reviews.
- **Real-Time Cart & Checkout:** Persistent cart state and seamless Stripe payment intent integration.
- **Order Tracking:** Track order statuses (pending, processing, shipped, delivered) with history.
- **Admin Dashboard:** In-app admin panel to easily upload new products and images directly from your gallery to Firebase Storage.
- **State Management:** Fully decoupled logic using `flutter_bloc`.
- **Backend:** Firebase Authentication, Cloud Firestore (with composite indexing), and Cloud Storage.

## 🛠 Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
* **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage)
* **Payments:** [Stripe](https://stripe.com/)
* **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc)
* **Routing:** [go_router](https://pub.dev/packages/go_router)
* **Image Handling:** [image_picker](https://pub.dev/packages/image_picker), [cached_network_image](https://pub.dev/packages/cached_network_image)

## 🚀 Getting Started

Follow these instructions to get a local copy up and running.

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)
* Android Studio / VS Code
* A [Firebase](https://console.firebase.google.com/) Project
* A [Stripe](https://dashboard.stripe.com/) Account

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/shopwave.git
cd shopwave
```

### 2. Setup Firebase

1. Create a new project in the Firebase Console.
2. Enable **Authentication** (Email/Password, Google, Apple, Anonymous).
3. Enable **Firestore Database** and **Firebase Storage**.
4. Run the Firebase CLI to configure your app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. Deploy the provided Firestore rules and indexes:
   ```bash
   firebase deploy --only firestore
   ```

### 3. Setup Stripe

1. Get your **Publishable Key** from the Stripe Dashboard.
2. In your app, pass the key during execution or set it as an environment variable in your run configuration:
   ```bash
   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
   ```

### 4. Install Dependencies & Run

```bash
flutter pub get
flutter run
```

## 📸 Screenshots

| Home Screen | Product Detail | Cart & Checkout | Admin Upload |
| :---: | :---: | :---: | :---: |
| <img src="https://via.placeholder.com/250x500.png?text=Home" width="200"/> | <img src="https://via.placeholder.com/250x500.png?text=Product" width="200"/> | <img src="https://via.placeholder.com/250x500.png?text=Checkout" width="200"/> | <img src="https://via.placeholder.com/250x500.png?text=Admin" width="200"/> |

*(Note: Replace placeholders with actual app screenshots)*

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](../../issues).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
