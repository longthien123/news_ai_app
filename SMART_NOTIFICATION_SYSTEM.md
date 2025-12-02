# 🎯 HỆ THỐNG THÔNG BÁO THÔNG MINH DỰA TRÊN HÀNH VI NGƯỜI DÙNG

## 📋 TỔNG QUAN
Hệ thống này tự động phân tích hành vi đọc tin của user và gợi ý các tin tức phù hợp khi user mở app.

## 🔄 LUỒNG HOẠT ĐỘNG CHÍNH

### 1. **Khi User Mở App** (Auto Trigger)
```
📱 User mở app 
    ↓
🔍 Phân tích lịch sử đọc 7 ngày qua
    ↓  
📊 Xác định categories yêu thích (top 5)
    ↓
📰 Lọc tin mới chưa đọc thuộc categories đó
    ↓
🤖 AI scoring và tạo thông báo cá nhân hóa
    ↓
📱 Gửi tối đa 5 notifications phù hợp
```

### 2. **Tracking Reading History**
```
📖 User đọc tin 
    ↓
💾 Lưu vào reading_history collection
    ↓
🔍 Phân tích category preference
    ↓
🎯 Cập nhật AI model cho lần tới
```

## 🛠️ CÁC COMPONENT CHÍNH

### **UserActivityTriggerService**
- **Chức năng**: Auto trigger khi user mở app
- **Phân tích**: Categories từ lịch sử đọc 7 ngày
- **Output**: Gợi ý tin mới cùng categories yêu thích

### **ReadingHistoryService** 
- **Chức năng**: Track lịch sử đọc tin
- **Data**: newsId, readAt, readDuration
- **Sử dụng**: Phân tích preference và keywords

### **SmartNewsHomePage**
- **Chức năng**: Wrapper cho NewsHomePage 
- **Auto-trigger**: Gọi UserActivityTrigger khi load
- **One-time**: Chỉ trigger 1 lần mỗi session

## 📊 THUẬT TOÁN PHÂN TÍCH

### **Category Analysis Algorithm:**
```dart
// Đếm frequency các categories đã đọc
final categoryCount = <String, int>{};

// Lọc categories có ít nhất 2 tin đọc
.where((entry) => entry.value >= 2)

// Lấy top 5 categories
.take(5)
```

### **Smart Filtering:**
```dart
// Chỉ lấy tin mới 3 ngày qua
final threeDaysAgo = DateTime.now().subtract(Duration(days: 3));

// Bỏ qua tin đã đọc
if (readNewsIds.contains(newsDoc.id)) continue;

// Tối đa 10 tin/category
.limit(10)
```

## 🎯 CÁCH SỬ DỤNG

### **1. Track Reading (Trong News Detail Page):**
```dart
import '../../notification/data/services/reading_history_service.dart';

// Khi user mở tin
await trackUserReadNews(userId, newsId);

// Khi user thoát (với thời gian đọc)
await trackUserReadingDuration(userId, newsId, readDuration);
```

### **2. Manual Trigger (Nếu cần):**
```dart
import '../main.dart';

// Trigger personalized notifications
await triggerUserOpenedApp(userId);
```

### **3. Kiểm tra logs:**
```dart
// Xem trong console
🔥 User 123 opened app - triggering personalized recommendations...
📊 User favorite categories: Thể thao, Công nghệ, Thời sự
📚 Found 8 unread news in favorite categories
📱 Sent 5 personalized notifications
✅ Personalized recommendations completed for user 123
```

## 📈 METRICS & ANALYTICS

### **User Activity Logs:**
- Collection: `users/{userId}/activity_logs`
- Actions: `app_opened`, `news_read`, `notification_clicked`

### **Reading History:**
- Collection: `users/{userId}/reading_history` 
- Fields: `newsId`, `readAt`, `readDuration`

### **Performance:**
- ⚡ **Trigger time**: ~2-3s cho phân tích và gợi ý
- 🎯 **Accuracy**: Dựa trên lịch sử đọc thực tế
- 📊 **Limit**: 5 notifications/session để tránh spam

## 🚀 TÍNH NĂNG NÂNG CAO

### **Fallback cho User Mới:**
```dart
// Nếu chưa có lịch sử đọc
final defaultCategories = ['Thời sự', 'Thế giới', 'Công nghệ', 'Thể thao'];
```

### **Anti-Spam Protection:**
```dart
// Giới hạn daily notifications
const maxNotifications = 5;

// Delay giữa notifications  
await Future.delayed(Duration(milliseconds: 300));
```

### **Smart Category Detection:**
```dart
// Yêu cầu tối thiểu 2 tin đã đọc trong category
.where((entry) => entry.value >= 2)

// Ưu tiên categories đọc gần đây
.orderBy('readAt', descending: true)
```

## 🔧 CẤU HÌNH

### **Constants có thể điều chỉnh:**
```dart
const HISTORY_ANALYSIS_DAYS = 7;      // Phân tích 7 ngày qua
const MAX_NEWS_PER_CATEGORY = 10;     // Tối đa 10 tin/category  
const MAX_NOTIFICATIONS_PER_SESSION = 5;  // Tối đa 5 thông báo/lần mở app
const MIN_CATEGORY_READS = 2;         // Tối thiểu 2 tin đọc để xem là quan tâm
const NEWS_FRESHNESS_DAYS = 3;        // Chỉ gợi ý tin mới 3 ngày qua
```

## 🎉 KẾT QUẢ MONG ĐỢI

✅ **User Experience**: Nhận thông báo cực kỳ phù hợp với sở thích  
✅ **Engagement**: Tăng tỷ lệ click vì nội dung được cá nhân hóa  
✅ **Retention**: User quay lại thường xuyên hơn nhờ nội dung chất lượng  
✅ **Intelligence**: Hệ thống học hỏi và cải thiện theo thời gian  

---

## 🐛 DEBUGGING

### **Kiểm tra logs:**
```bash
# Trigger logs
🔥 User xyz opened app - triggering personalized recommendations...

# Analysis logs  
📊 Category analysis: {Thể thao: 5, Công nghệ: 3, Thời sự: 2}

# Result logs
📱 Sent 4 personalized notifications
✅ Personalized recommendations completed
```

### **Test cases:**
1. **User mới**: Nhận default recommendations
2. **User cũ**: Nhận theo categories đã phân tích
3. **Không có tin mới**: Không gửi notification
4. **Daily limit**: Dừng khi đạt giới hạn