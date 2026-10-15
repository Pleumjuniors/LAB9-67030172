# คำตอบประกอบใบงานสัปดาห์ที่ 9

## ส่วนที่ 5.1 — Repository Pattern

1. การเพิ่ม `ItemRepositoryFirestore` ทำให้แหล่งข้อมูล Firestore แยกจาก `ItemRepositoryApi` และทำให้ `HomePage` เรียกใช้ผ่านสัญญา `ItemRepository` เดียวกันได้ การเรียก Firestore ตรงจาก Widget จะผูก UI เข้ากับบริการเฉพาะและทำให้เปลี่ยนหรือทดสอบแหล่งข้อมูลยากขึ้น
2. หากทุก Widget พึ่งพา Interface และเปลี่ยนแหล่งข้อมูลที่จุดประกอบแอป จะเปลี่ยนเพียงไฟล์ที่สร้าง/ส่ง Repository (เช่น `main.dart`) และเพิ่ม Implementation ใหม่ โดยไม่ต้องแก้ Widget ที่ใช้งาน Interface

## ส่วนที่ 7.1 — Security Rules

การซ่อนปุ่มแก้ไขในแอปเป็นเพียงการควบคุมหน้าจอ ผู้ใช้ยังเรียก Firebase API โดยตรงหรือดัดแปลงแอปเพื่อส่งคำขอเองได้ Security Rules ตรวจสอบคำขอที่ Firebase ก่อนอ่านหรือเขียนข้อมูล จึงต้องกำหนดสิทธิ์บนเซิร์ฟเวอร์ เช่น อนุญาตสร้างเมื่อผู้ใช้ล็อกอินและ `sellerId` ตรงกับ UID และอนุญาตแก้ไข/ลบเฉพาะเอกสารที่ผู้ใช้เป็นเจ้าของ

## ส่วนที่ 3.1 — Google Sign-In

`idToken` ใช้ยืนยันตัวตนบัญชี Google กับ Firebase Authentication ส่วน `accessToken` ใช้เป็นสิทธิ์เข้าถึง Google APIs ตาม scope ที่ร้องขอ โดยโค้ดส่ง token เหล่านี้ให้ `GoogleAuthProvider.credential()` เพื่อสร้าง credential ที่ Firebase ใช้ลงชื่อเข้าใช้

## การตั้งค่าที่ต้องทำใน Firebase Console และอุปกรณ์

- เปิด Email/Password และ Google providers ใน Firebase Authentication
- เพิ่ม SHA-1 ของ debug keystore ให้ Android app ใน Firebase Project แล้วดาวน์โหลด `google-services.json` ฉบับใหม่
- สร้าง Firestore Database และ Storage bucket
- Publish Firestore/Storage Security Rules ที่จำกัดการสร้าง แก้ไข และลบตาม UID ของผู้ขาย
- ทดสอบสมัคร/ล็อกอิน, Google Sign-In, โพสต์สินค้า และถ่ายภาพ Checkpoint จาก Firebase Console กับอุปกรณ์จริงหรือ Emulator แบบ Google Play

ไฟล์ Firebase ที่มีอยู่ในโปรเจกต์ชี้ไปยัง Firebase project `lab-9firebase`; ต้องตรวจสอบว่าเป็นโปรเจกต์ที่ผู้เรียนใช้งานและมีสิทธิ์เข้าถึงก่อนทดสอบบริการจริง
