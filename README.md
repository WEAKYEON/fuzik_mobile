# FUZIK Collaboration Application

แอปพลิเคชันสำหรับการจัดการไฟล์งานและการ Collaboration ของทีม Fuzik พัฒนาด้วย Flutter และเชื่อมต่อกับ Supabase สำหรับการจัดการ Backend แบบ Real-time

## Features
- **Secure Authentication:** ระบบ Login ที่ปลอดภัยด้วย Supabase Auth
- **File Management:** อัปโหลดและจัดการไฟล์งานผ่าน Inventory
- **Real-time Collaboration:** เชื่อมต่อและแชร์งานกับเพื่อนร่วมทีมได้ทันที
- **Responsive UI:** รองรับการใช้งานทั้งบนมือถือและแท็บเล็ต

## Technology Stack
- **Frontend:** Flutter
- **Backend:** Supabase (Auth, Storage, Database)
- **State Management:** SetState & IndexedStack

## Getting Started

### Prerequisites
- Flutter SDK (version 3.x.x ขึ้นไป)
- ติดตั้ง Dependencies: `flutter pub get`

### Configuration
1. สร้างไฟล์ `.env` ไว้ในโฟลเดอร์หลักของโปรเจกต์
2. เพิ่มค่าตัวแปรดังนี้:
   ```env
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_KEY
   ```

### รันโปรเจกต์:
```Bash
flutter run
```
### License
This project is licensed under the MIT License.