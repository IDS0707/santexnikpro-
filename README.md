# Santexnika Pro

B2B santexnika (plumbing) platformasi — ikkita Flutter mobil ilova va bitta backend.

## Tarkib

| Papka | Tavsif | Texnologiya |
|-------|--------|-------------|
| [`dokon/`](dokon/) | Mijoz (do'kon) ilovasi — "Santexnik Pro" | Flutter, Material 3, Provider |
| [`admin/`](admin/) | Admin panel ilovasi | Flutter |
| [`backend/`](backend/) | Multi-tenant REST API | FastAPI, asyncpg, PostgreSQL |

## Imkoniyatlar

- **Multi-tenant** — bir nechta do'kon, har biri parol bilan himoyalangan
- **Mijoz ilovasi** — kategoriyalar, mahsulotlar, savat, buyurtma, hisoblagich, bonuslar
- **Admin panel** — mahsulot/kategoriya/narx boshqaruvi, buyurtmalar, haydovchilar, bonuslar
- **Tungi/kunduzgi rejim**, ko'k aksent dizayn
- **Bildirishnomalar** — yangi buyurtma haqida

## Ishga tushirish

### Backend
```bash
cd backend
# DB_DSN va JWT_SECRET muhit o'zgaruvchilarini sozlang
uvicorn main:app --host 0.0.0.0 --port 8091
```

### Dokon / Admin (Flutter)
```bash
cd dokon   # yoki admin
flutter pub get
flutter run            # qurilma/emulyatorda
flutter run -d chrome  # brauzerda
flutter build apk      # APK
```

## Muhit o'zgaruvchilari (backend)

| O'zgaruvchi | Tavsif |
|-------------|--------|
| `DB_DSN` | PostgreSQL ulanish satri |
| `JWT_SECRET` | JWT imzo kaliti |
| `API_PUBLIC` | Tashqi API manzili (yuklangan fayllar uchun) |

> Maxfiy ma'lumotlar (parollar, tokenlar) kodga yozilmaydi — faqat muhit o'zgaruvchilari orqali.

---
© IDS Group
