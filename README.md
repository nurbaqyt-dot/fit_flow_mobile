# FitFlow - Fitness Tracking Application

![image alt](https://github.com/nurbaqyt-dot/fit_flow_mobile/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202026-06-06%20%D0%B2%2016.20.43.png?raw=true)

**FitFlow** is a modern mobile application for tracking workouts, competing with friends, and achieving fitness goals.

## 🚀 Features

### Core Functionality

- **🏋️ Workouts** - Choose from various types of exercises:
  - Strength (Strength training)
  - Cardio (Cardiovascular exercises)
  - HIIT (High-intensity interval training)
  - Yoga (Yoga and stretching)
  - Running (Running workouts)
  - Cycling (Cycling workouts)

- **📊 Progress Tracking** - View your statistics:
  - Number of completed workouts
  - Total streaks (consecutive days)
  - Number of followers
  - Weekly activity overview

- **👥 Social Features**:
  - Compete with friends
  - Share workout results
  - Track friend activity
  - Achievement and reward system

- **🎯 User Profile**:
  - Edit personal information
  - Upload avatar
  - View biography
  - Workout history

- **📈 Analytics**:
  - Detailed statistics by exercise type
  - Weekly activity report
  - Achievement history
  - Results comparison

## 📱 Application Screens

### Authentication
- **Login** - Sign in with email and password
- **Registration** - Create a new account
- **Password Recovery** - "Forgot Password?" option

### Home Screen
- User greeting
- "Start Workout" button
- Recent workout history
- Weekly activity overview

### Exercise Selection
- **Strength** - Strength exercises (4 exercises)
- **Cardio** - Cardio workouts (4 exercises)
- **HIIT** - Interval training (4 exercises)
- **Yoga** - Yoga workouts (4 exercises)
- **Running** - Running workouts (4 exercises)
- **Cycling** - Cycling workouts (4 exercises)

Each workout contains:
- Exercise name
- Number of sets
- Number of reps/time
- Remaining until completion

### Profile
- User information (name, username, level)
- Profile editing
- Avatar upload
- Statistics (workouts, streak, followers)
- Profile description

### Social Section
- Friends list
- Other user profiles
- Competitions
- Activity feeds

## 🛠️ Technology Stack

- **Frontend Framework**: React Native / Flutter
- **Backend**: Firebase
  - Authentication (User authentication)
  - Firestore (Database)
  - Storage (File storage)
  - Cloud Functions (Server functions)
- **UI Design**: Dark theme with bright neon green color scheme (#CCFF00)
- **State Management**: Redux / Context API
- **Navigation**: React Navigation / Navigation Stack

## 🎨 Design

### Color Scheme
- **Primary Color**: Bright neon green (#CCFF00)
- **Background**: Black (#000000)
- **Secondary Text**: Gray (#808080)
- **Accents**: Neon green for active elements

### Typography
- Modern, readable font
- Clear icons for each exercise type
- High contrast for dark interface

## 📋 Installation Requirements

### For Mobile Application

**iOS:**
- iOS 13.0 or higher
- Xcode 12.0+
- CocoaPods

**Android:**
- Android 8.0 (API 26) or higher
- Android Studio
- Gradle 7.0+

### Dependencies

```json
{
  "react-native": "^0.71.0",
  "firebase": "^9.0.0",
  "react-navigation": "^6.0.0",
  "redux": "^4.0.0",
  "axios": "^0.27.0"
}
```

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/fitflow.git
cd fitflow
```

### 2. Install Dependencies
```bash
npm install
# or
yarn install
```

### 3. Firebase Configuration

Create a `config/firebase.js` file:
```javascript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-app.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "SENDER_ID",
  appId: "APP_ID"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
```

### 4. Run the Application

**iOS:**
```bash
npx react-native run-ios
```

**Android:**
```bash
npx react-native run-android
```

## 📚 API Documentation

### Authentication
```javascript
// User registration
signUp(email, password, userData)

// User login
signIn(email, password)

// User logout
signOut()

// Password recovery
resetPassword(email)
```

### Workouts
```javascript
// Get all workouts
getAllWorkouts()

// Create new workout
createWorkout(workoutData)

// Update workout
updateWorkout(workoutId, updates)

// Delete workout
deleteWorkout(workoutId)
```

### User Profile
```javascript
// Get user profile
getUserProfile(userId)

// Update user profile
updateUserProfile(userId, profileData)

// Upload avatar
uploadAvatar(userId, imageFile)
```

### Social Functions
```javascript
// Add friend
addFriend(userId, friendId)

// Get friends list
getFriends(userId)

// Get activity feed
getActivityFeed(userId)
```

## 🐛 Troubleshooting

### Issue: App freezes on splash screen
**Solution:**
1. Check Firebase configuration
2. Ensure `google-services.json` and `GoogleService-Info.plist` files are added
3. Check console logs
4. Clear cache: `npm start -- --reset-cache`

### Issue: Authentication errors
**Solution:**
1. Verify Firebase API keys are correct
2. Ensure Authentication is enabled in Firebase Console
3. Check Firestore security rules

### Issue: Images not loading
**Solution:**
1. Check camera and gallery permissions
2. Ensure Firebase Storage is properly configured
3. Check file sizes

## 📖 Project Structure

```
fitflow/
├── src/
│   ├── screens/
│   │   ├── AuthStack/
│   │   │   ├── LoginScreen.js
│   │   │   ├── SignupScreen.js
│   │   │   └── ForgotPasswordScreen.js
│   │   ├── HomeStack/
│   │   │   ├── HomeScreen.js
│   │   │   ├── WorkoutScreen.js
│   │   │   ├── ExerciseDetailsScreen.js
│   │   │   └── HistoryScreen.js
│   │   ├── ProfileStack/
│   │   │   ├── ProfileScreen.js
│   │   │   ├── EditProfileScreen.js
│   │   │   └── StatisticsScreen.js
│   │   └── SocialStack/
│   │       ├── FriendsScreen.js
│   │       ├── CompetitionScreen.js
│   │       └── UserProfileScreen.js
│   ├── components/
│   │   ├── Button.js
│   │   ├── Card.js
│   │   ├── ExerciseCard.js
│   │   └── StatCard.js
│   ├── navigation/
│   │   ├── RootNavigator.js
│   │   └── BottomTabNavigator.js
│   ├── redux/
│   │   ├── slices/
│   │   │   ├── authSlice.js
│   │   │   ├── workoutSlice.js
│   │   │   └── userSlice.js
│   │   └── store.js
│   ├── services/
│   │   ├── firebase.js
│   │   ├── authService.js
│   │   ├── workoutService.js
│   │   └── userService.js
│   ├── utils/
│   │   ├── constants.js
│   │   └── helpers.js
│   └── App.js
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── config/
│   ├── firebase.js
│   └── constants.js
├── .env.example
├── package.json
└── README.md
```

## 🔐 Security

- All passwords are stored in Firebase (server-side hashing)
- Authentication tokens are stored securely
- API requests are protected by Firebase Security Rules
- Sensitive data is not stored in localStorage

## 📈 Future Improvements

- [ ] Integration with Apple Health and Google Fit
- [ ] Smartwatch synchronization
- [ ] AI-powered personalized recommendations
- [ ] Exercise video tutorials
- [ ] Nutrition and calorie tracker
- [ ] Chat with trainer
- [ ] Premium subscription

---

**Developed by:** [Your Name]

**FitFlow** - Your personal trainer in your pocket! 💪
