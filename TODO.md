# Future Features - University E-Library

## 🔜 Planned Features

### 1. Admin: Add/Manage Books
**Status:** Pending (waiting for server/database decision)

**Description:**
- Admin dapat menambah buku baru via aplikasi
- Form input: title, author, type (physical/ebook), stock, cover, dll
- Untuk buku fisik: input lokasi rak, jumlah stok
- Untuk ebook: upload file PDF atau input URL

**Considerations:**
- Mekanisme berbeda untuk buku fisik (offline) vs ebook (online)
- Perlu backend/server untuk:
  - Menyimpan data buku secara persistent
  - Upload & hosting file PDF untuk ebook
  - Sinkronisasi data antar device

**Migration Plan:**
1. Ganti MockDataService → API Service (REST/GraphQL)
2. Setup backend (Firebase/Supabase/Custom server)
3. Implementasi file upload untuk ebook PDF
4. Admin tetap menambah buku via aplikasi Flutter

---

## ✅ Completed Features
- [x] Student: Browse & search books
- [x] Student: Book physical books (Click & Collect)
- [x] Student: Read ebooks
- [x] Student: View bookings with QR code
- [x] Admin: Dashboard statistics
- [x] Admin: Scan QR & validate booking
- [x] Admin: Process book handover
- [x] Role-based authentication
