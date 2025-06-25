# 📱 Local Business Discovery & Promotion App

A Flutter-based mobile application that connects local businesses with customers by providing a centralized platform for business discovery, promotion, reviews, and real-time interactions — especially tailored for communities in Ethiopia.

---

## 🖼️ App Screenshots

| Home                                                                                       | Search                                                                                        | Business Profile                                                                               | Review                                                                                        |
| ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| ![Home](https://raw.githubusercontent.com/TAEMZ/Localbusiness/main/assets/backg/image.png) | ![Search](https://raw.githubusercontent.com/TAEMZ/Localbusiness/main/assets/backg/image2.png) | ![Profile](https://raw.githubusercontent.com/TAEMZ/Localbusiness/main/assets/backg/image3.png) | ![Review](https://raw.githubusercontent.com/TAEMZ/Localbusiness/main/assets/backg/image1.png) |

---

## 📌 Overview

This project was developed as part of a final year BSc Computer Science thesis at Werabe University. It aims to bridge the gap between small/medium businesses and their communities through a modern digital platform. By leveraging Firebase, Google Maps, and Flutter, it ensures real-time updates, geolocation, and an intuitive multilingual UI/UX experience.

## ✨ Features

### 👤 Users

- 🔐 Secure login (Email/Password, Google Auth)
- 🔍 Search businesses by name, category, or location
- ⭐ Leave and manage reviews and ratings
- ❤️ Bookmark or favorite businesses
- 🗺️ Get directions via integrated Maps
- 🌐 Multilingual interface (English, Amharic, Siltigna)

### 🧑‍💼 Business Owners

- 🏢 Create and manage business profiles
- 📈 View analytics (clicks, searches, reviews)
- 🗨️ Respond to user reviews
- 📣 Promote services and announcements

### 🔧 Admin

- ✅ Approve or reject business listings
- 🚨 Moderate flagged users, reviews, and businesses
- 🛡️ Ensure data integrity and community standards

## 📱 Tech Stack

| Layer      | Technology                 |
| ---------- | -------------------------- |
| Frontend   | Flutter + Dart             |
| Backend    | Firebase (Firestore, Auth) |
| Maps & Geo | Google Maps API            |
| Design     | Figma, Draw.io, Lucidchart |
| Dev Tools  | VS Code                    |

## 🧠 System Modules

- **Authentication**: Email/password + RBAC
- **Business Listings**: Add/edit/delete with analytics
- **Review System**: Real-time, moderated, with notifications
- **Favorites/Bookmarks**: Personalized business lists
- **Reporting & Moderation**: Flag users/reviews/businesses

## 📊 Data Models

Collections in Firebase include:

- `users`: user profile, role (user/owner)
- `businesses`: details like name, category, location, owner
- `reviews`: linked to users and businesses
- `favorites` & `bookmarks`: user-saved businesses
- `flagged`: reports for inappropriate users/reviews/businesses

## 📈 Architecture

- **Modular MVC Structure**
- **Firebase Real-time Sync**
- **Flutter Widgets for Component-Based UI**
- **Cross-platform Compatibility (target: Android, iOS-ready)**

## ⚙️ Development Workflow

1. Requirement gathering (interviews + surveys)
2. Iterative SDLC model
3. UI/UX mockups via Figma
4. Firebase integration & security rules
5. Testing & deployment

## 📦 Installation

```bash
git clone https://github.com/TAEMZ/Localbusiness.git
cd Localbusiness
flutter pub get
flutter run
```
