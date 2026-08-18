# FUZIK Collaboration Application

A collaboration and file management application designed for the Fuzik team. Built with Flutter and integrated with Supabase for real-time backend management.

## Features
- **Secure Authentication:** Secure login system powered by Supabase Auth.
- **File Management:** Upload, organize, and manage project files via the Inventory system.
- **Real-time Collaboration:** Instantly connect and share work with team members.
- **Responsive UI:** Optimized for both mobile and tablet devices.

## Technology Stack
- **Frontend:** Flutter
- **Backend:** Supabase (Auth, Storage, Database)
- **State Management:** `setState` & `IndexedStack`

## Getting Started

### Prerequisites
- Flutter SDK (version 3.x.x or higher)
- Install dependencies by running:
   ```env
   flutter pub get
   ```

### Configuration
1. Create a .env file in the root directory of the project.
2. Add your Supabase credentials:
   ```env
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_KEY
   ```
(Note: Do not commit the .env file to version control. It should be added to your .gitignore.)

### Running the Project
To run the application, execute the following command:
```Bash
flutter run
```
### License
This project is licensed under the MIT License.
