# 🔔 AI Smart Notifications Feature

## 📝 Tổng quan

Feature **AI Smart Notifications** sử dụng **Gemini AI** để phân tích sở thích người dùng và gửi thông báo tin tức được cá nhân hóa. Hệ thống tự động học từ hành vi đọc tin, chọn thời điểm tối ưu để gửi thông báo, và tránh spam.

---

## ✨ Tính năng chính

### 1. **Gợi ý nội dung bằng AI**
- 🤖 Gemini AI phân tích tin tức vs sở thích user → tính **relevance score (0.0-1.0)**
- 📌 Track categories user đọc nhiều, keywords quan tâm
- ✍️ Tự động tạo nội dung thông báo hấp dẫn, cá nhân hóa

### 2. **Thời điểm thông minh**
- ⏰ Phân tích giờ user thường mở app → gửi vào **giờ vàng**
- 🚫 Giới hạn 3-5 thông báo/ngày (tùy chỉnh được) → tránh spam
- 📊 Schedule thông tin thường, gửi ngay breaking news

### 3. **Thông báo theo ngữ cảnh**
- 🔥 **Breaking news** (priority cao) → gửi ngay lập tức
- 📰 **Tin thường** → gom gửi vào giờ vàng tiếp theo
- 💡 **Contextual**: Đang đọc "Bóng đá" → push tin liên quan

---

## 🏗️ Kiến trúc Clean Architecture

```
lib/features/notification/
├── domain/
│   ├── entities/
│   │   ├── user_preference.dart         # Sở thích user (categories, keywords, active hours)
│   │   ├── reading_session.dart         # Phiên đọc tin (track behavior)
│   │   └── smart_notification.dart      # Thông báo với AI score
│   ├── repositories/
│   │   ├── notification_repository.dart
│   │   └── user_behavior_repository.dart
│   └── usecases/
│       ├── get_notifications_usecase.dart
│       ├── get_smart_notif_usecase.dart
│       ├── analyze_user_behavior_usecase.dart
│       ├── create_smart_notification_usecase.dart
│       └── track_reading_session_usecase.dart
├── data/
│   ├── models/                          # JSON serialization models
│   ├── datasources/
│   │   ├── notification_datasource.dart # FCM + Local notifications
│   │   └── user_behavior_datasource.dart # Firestore tracking
│   ├── repositories/                    # Repository implementations
│   └── services/
│       └── gemini_recommendation_service.dart  # ⭐ AI core
├── presentation/
│   ├── cubit/
│   │   ├── notification_cubit.dart
│   │   └── notification_state.dart
│   ├── pages/
│   │   ├── notifications_page.dart      # Danh sách thông báo
│   │   └── notification_settings_page.dart  # Cài đặt
│   └── widgets/
│       └── notification_badge_icon.dart # Icon chuông + badge count
```

---

## 🚀 Cách sử dụng

### 1. **Setup Gemini API Key**

Mở file `lib/features/news/data/datasources/remote/gemini_config.dart`:

```dart
class GeminiConfig {
  static const String apiKey = 'YOUR_GEMINI_API_KEY'; // ← Thay key thật
  static const String modelName = 'gemini-pro';
}
```

**Lấy key tại:** https://makersuite.google.com/app/apikey

### 2. **Thêm Notification Icon vào AppBar**

Trong `NewsHomePage` hoặc layout chính:

```dart
import 'features/notification/presentation/widgets/notification_badge_icon.dart';

AppBar(
  actions: [
    const NotificationBadgeIcon(), // ← Icon chuông với badge count
    // ... other icons
  ],
)
```

### 3. **Track Reading Behavior**

Trong `NewsDetailPage`, khi user đọc tin:

```dart
import 'features/notification/domain/usecases/track_reading_session_usecase.dart';
import 'features/notification/domain/entities/reading_session.dart';

// Khi user mở tin
final startTime = DateTime.now();

// Khi user rời khỏi tin
final session = ReadingSession(
  userId: currentUserId,
  newsId: newsId,
  category: category,
  title: title,
  startedAt: startTime,
  endedAt: DateTime.now(),
  durationSeconds: DateTime.now().difference(startTime).inSeconds,
  isBookmarked: isBookmarked,
  isCompleted: userScrolledToBottom,
);

await trackReadingSessionUseCase(session);
```

### 4. **Tạo Smart Notification (Admin/Backend)**

Khi có tin mới, gọi use case để tạo notification:

```dart
import 'features/notification/domain/usecases/create_smart_notification_usecase.dart';

await createSmartNotificationUseCase(
  userId: userId,
  newsId: newsId,
  title: newsTitle,
  body: 'Tin bạn có thể thích: ${newsTitle}',
  category: category,
  imageUrl: imageUrl,
  aiRelevanceScore: 0.85, // AI tính từ GeminiRecommendationService
  type: NotificationType.recommended,
);
```

### 5. **Load Notifications**

Trong UI page:

```dart
// Load tất cả notifications
context.read<NotificationCubit>().loadNotifications(userId);

// Load chỉ smart notifications (sorted by relevance)
context.read<NotificationCubit>().loadSmartNotifications(userId);

// Phân tích behavior và update preferences
context.read<NotificationCubit>().analyzeUserBehavior(userId);
```

---

## 🎨 UI Components

### NotificationsPage
- Danh sách thông báo với icon theo type (⚡ breaking, ⭐ recommended, 💡 contextual)
- Badge priority (Quan trọng/Thường/Thấp)
- Timestamp tương đối (vừa xong, 2 giờ trước...)
- Tap → navigate to news detail

### NotificationSettingsPage
- ✅ Bật/tắt AI notifications
- 🎚️ Slider giới hạn thông báo/ngày (1-10)
- 🏷️ Chọn categories quan tâm (FilterChip)
- 📊 Button "Phân tích ngay" → trigger AI analysis

### NotificationBadgeIcon
- Icon chuông với badge đỏ hiển thị số unread
- Tự động update realtime qua BLoC

---

## 🔥 GeminiRecommendationService - AI Core

### 3 chức năng chính:

#### 1. **calculateRelevanceScore**
```dart
final score = await geminiService.calculateRelevanceScore(
  news: newsEntity,
  userPreference: userPreference,
);
// → Trả về 0.0-1.0 (1.0 = rất phù hợp)
```

**AI Prompt:**
- Input: user categories, keywords, news title/content
- Output: 1 số duy nhất 0.0-1.0
- Fallback: rule-based matching nếu API fail

#### 2. **generatePersonalizedNotificationBody**
```dart
final body = await geminiService.generatePersonalizedNotificationBody(
  news: newsEntity,
  userPreference: userPreference,
);
// → Trả về nội dung 60 ký tự, hấp dẫn
```

**AI Prompt:**
- Tạo câu ngắn gọn, nhấn mạnh điểm liên quan sở thích user
- Không emoji, tiếng Việt
- Fallback: lấy 60 ký tự đầu của content

#### 3. **extractKeywordsFromReadingHistory**
```dart
final keywords = await geminiService.extractKeywordsFromReadingHistory(
  titles: listOfTitles,
  categories: listOfCategories,
);
// → Trả về 5-10 keywords chính
```

**AI Prompt:**
- Phân tích 20 tin gần nhất user đã đọc
- Trích xuất danh từ/cụm danh từ quan trọng
- Fallback: word frequency counting

---

## 📦 Firestore Structure

```
users/{userId}/
  ├── notifications/{notifId}          # Smart notifications
  │   ├── id: string
  │   ├── newsId: string
  │   ├── title: string
  │   ├── body: string
  │   ├── type: "breaking" | "recommended" | "contextual" | "digest"
  │   ├── priority: "high" | "normal" | "low"
  │   ├── aiRelevanceScore: number (0.0-1.0)
  │   ├── scheduledAt: timestamp
  │   ├── sentAt: timestamp?
  │   └── isRead: boolean
  │
  ├── readingSessions/{sessionId}      # Track behavior
  │   ├── newsId: string
  │   ├── category: string
  │   ├── title: string
  │   ├── startedAt: timestamp
  │   ├── durationSeconds: number
  │   ├── isBookmarked: boolean
  │   └── isCompleted: boolean
  │
  └── preferences/userPreference       # AI-analyzed preferences
      ├── favoriteCategories: string[]
      ├── keywords: string[]
      ├── activeHours: map<hour, count>
      ├── dailyNotificationLimit: number
      ├── enableSmartNotifications: boolean
      └── lastAnalyzedAt: timestamp
```

---

## 🔐 Firestore Security Rules

```javascript
match /users/{userId} {
  // Notifications
  match /notifications/{notifId} {
    allow read, write: if request.auth.uid == userId;
  }
  
  // Reading sessions
  match /readingSessions/{sessionId} {
    allow read, write: if request.auth.uid == userId;
  }
  
  // Preferences
  match /preferences/{prefId} {
    allow read, write: if request.auth.uid == userId;
  }
}
```

---

## 🧪 Testing

### Manual Test Flow:

1. **Test Reading Tracking:**
   - Đọc 5-10 tin thuộc categories khác nhau
   - Check Firestore: `users/{userId}/readingSessions`

2. **Test AI Analysis:**
   - Vào Settings → tap "Phân tích ngay"
   - Check Firestore: `users/{userId}/preferences/userPreference`
   - Verify: `favoriteCategories`, `keywords`, `activeHours`

3. **Test Smart Notification:**
   - Tạo tin mới (admin)
   - Trigger `createSmartNotification` với AI score cao
   - Check: notification xuất hiện trong NotificationsPage
   - Verify: badge count tăng

4. **Test Scheduling:**
   - Tạo nhiều notifications cùng lúc
   - Verify: chỉ notifications có score cao được gửi ngay
   - Verify: notifications thường được schedule vào giờ vàng

---

## 📈 Future Enhancements

- [ ] **A/B Testing:** test notification timing & content variants
- [ ] **Push notifications thật:** integrate FCM server-side
- [ ] **Notification actions:** "Đọc ngay", "Lưu sau", "Không quan tâm"
- [ ] **Advanced AI:** sentiment analysis, trending topics
- [ ] **Analytics dashboard:** open rate, click rate, engagement

---

## 🐛 Troubleshooting

### ❌ AI trả về null/rỗng
- **Nguyên nhân:** Gemini API key không hợp lệ hoặc API overload
- **Fix:** Check `gemini_config.dart`, đảm bảo key đúng. Fallback tự động chạy.

### ❌ Notification không hiển thị
- **Nguyên nhân:** BlocProvider chưa wrap NotificationCubit
- **Fix:** Check `main.dart`, đảm bảo `NotificationCubit` trong `MultiBlocProvider`

### ❌ Badge count không update
- **Nguyên nhân:** Chưa gọi `loadNotifications(userId)`
- **Fix:** Gọi trong `initState` của page chính hoặc `AuthWrapper`

---

## 📚 Dependencies

- `firebase_messaging: ^15.1.6` — FCM push notifications
- `flutter_local_notifications: ^18.0.1` — Local notifications
- `google_generative_ai: ^0.4.6` — Gemini AI
- `cloud_firestore: ^5.6.12` — Database
- `flutter_bloc: ^8.1.3` — State management
- `equatable: ^2.0.5` — Value equality

---

## 👨‍💻 Tác giả & Liên hệ

Feature được phát triển với Clean Architecture + AI-powered recommendations.

**Stack:** Flutter + Firebase + Gemini AI  
**Pattern:** BLoC/Cubit + Repository Pattern  

---

🎉 **Chúc bạn code vui!** 🚀
