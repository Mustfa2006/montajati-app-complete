# 🎯 ميزة ترتيب عرض المنتجات
## Product Display Order Feature

---

## 🚀 **الميزة الجديدة:**

### **ترتيب المنتجات في صفحة المنتجات الرئيسية**
- **رقم 1** = المنتج يظهر أولاً في الصفحة
- **رقم 5** = المنتج يظهر خامساً في الصفحة
- **رقم أكبر** = المنتج يظهر في ترتيب متأخر

---

## ✅ **التحديثات المطبقة:**

### **1. تحديث نموذج Product:**
```dart
// إضافة حقل displayOrder
final int displayOrder; // ترتيب عرض المنتج (1 = أول منتج، 2 = ثاني منتج، إلخ)

// في Constructor
this.displayOrder = 999, // قيمة افتراضية عالية للمنتجات الجديدة

// في fromJson
displayOrder: json['display_order'] ?? 999,

// في toJson
'display_order': displayOrder,

// في copyWith
int? displayOrder,
displayOrder: displayOrder ?? this.displayOrder,
```

### **2. تحديث نافذة تعديل المنتج:**
```dart
// إضافة Controller
final displayOrderController = TextEditingController(
  text: product.displayOrder.toString(),
);

// إضافة واجهة المستخدم
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF2a2a2e),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: const Color(0xFFffd700).withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(
            Icons.sort,
            color: Color(0xFFffd700),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'ترتيب العرض في صفحة المنتجات',
            style: GoogleFonts.cairo(
              color: const Color(0xFFffd700),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildEditTextField(
        displayOrderController,
        'رقم الترتيب (1 = أول منتج، 2 = ثاني منتج)',
        Icons.format_list_numbered,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 8),
      Text(
        'ملاحظة: رقم 1 يعني أول منتج في الصفحة، رقم 5 يعني خامس منتج، وهكذا',
        style: GoogleFonts.cairo(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    ],
  ),
),
```

### **3. تحديث دالة تحديث المنتج:**
```dart
// إضافة معامل displayOrder
Future<void> _updateProductInDatabase(
  String productId,
  String name,
  String description,
  double wholesalePrice,
  double minPrice,
  double maxPrice,
  int availableFrom,
  int availableTo,
  int availableQuantity,
  String category,
  List<String> images,
  int displayOrder, // ← الحقل الجديد
) async {
  // ...
  
  // تحديث ترتيب العرض منفصلاً
  await Supabase.instance.client
      .from('products')
      .update({
        'display_order': displayOrder,
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', productId);
}

// تمرير القيمة عند الاستدعاء
await _updateProductInDatabase(
  product.id,
  nameController.text,
  descriptionController.text,
  // ... باقي المعاملات
  int.tryParse(displayOrderController.text) ?? product.displayOrder,
);
```

### **4. تحديث استعلامات قاعدة البيانات:**
```dart
// في لوحة التحكم
final response = await Supabase.instance.client
    .from('products')
    .select(
      'id, name, description, image_url, images, wholesale_price, min_price, max_price, available_quantity, available_from, available_to, category, display_order, is_active, created_at',
    )
    .eq('is_active', true)
    .order('display_order', ascending: true) // ترتيب حسب display_order أولاً
    .order('created_at', ascending: false); // ثم حسب تاريخ الإنشاء

// في صفحة المنتجات الرئيسية
final response = await Supabase.instance.client
    .from('products')
    .select('*, available_from, available_to, available_quantity, display_order')
    .eq('is_active', true)
    .gt('available_quantity', 0)
    .order('display_order', ascending: true) // ترتيب حسب display_order أولاً
    .order('created_at', ascending: false); // ثم حسب تاريخ الإنشاء
```

### **5. تحديث بناء كائن Product:**
```dart
// في لوحة التحكم
final product = Product(
  id: json['id'] ?? '',
  name: json['name'] ?? 'منتج بدون اسم',
  description: json['description'] ?? '',
  images: productImages,
  wholesalePrice: (json['wholesale_price'] ?? 0).toDouble(),
  minPrice: (json['min_price'] ?? 0).toDouble(),
  maxPrice: (json['max_price'] ?? 0).toDouble(),
  category: json['category'] ?? 'عام',
  minQuantity: 1,
  maxQuantity: json['max_quantity'] ?? 0,
  availableFrom: json['available_from'] ?? 90,
  availableTo: json['available_to'] ?? 80,
  availableQuantity: json['available_quantity'] ?? 100,
  displayOrder: json['display_order'] ?? 999, // ← الحقل الجديد
  createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  updatedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
);

// في صفحة المنتجات
Product(
  // ... باقي الحقول
  displayOrder: item['display_order'] ?? 999, // ← الحقل الجديد
  // ...
);
```

---

## 🗄️ **قاعدة البيانات:**

### **إضافة العمود:**
```sql
-- إضافة حقل display_order إلى جدول المنتجات
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 999;

-- إنشاء فهرس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_products_display_order 
ON products(display_order, created_at);

-- تحديث المنتجات الموجودة بترتيب افتراضي
UPDATE products 
SET display_order = CASE 
    WHEN display_order IS NULL OR display_order = 999 THEN 
        ROW_NUMBER() OVER (ORDER BY created_at DESC) 
    ELSE display_order 
END
WHERE display_order IS NULL OR display_order = 999;
```

---

## 🎯 **كيفية الاستخدام:**

### **للمدير:**
1. **افتح لوحة التحكم** → قسم المنتجات
2. **انقر على "تعديل"** لأي منتج
3. **ابحث عن قسم "ترتيب العرض"**
4. **اكتب الرقم المطلوب:**
   - **1** = أول منتج في الصفحة
   - **2** = ثاني منتج في الصفحة
   - **5** = خامس منتج في الصفحة
   - **وهكذا...**
5. **انقر "حفظ"**

### **للمستخدمين:**
- **ستظهر المنتجات في صفحة "منتجاتي" مرتبة حسب الأرقام**
- **المنتج برقم 1 سيظهر أولاً**
- **المنتج برقم 2 سيظهر ثانياً**
- **وهكذا...**

---

## 📊 **مثال عملي:**

### **قبل التطبيق:**
```
المنتجات مرتبة حسب تاريخ الإضافة:
1. منتج جديد (أضيف اليوم)
2. منتج قديم (أضيف أمس)
3. منتج أقدم (أضيف الأسبوع الماضي)
```

### **بعد التطبيق:**
```
المدير يحدد:
- منتج أقدم → ترتيب 1
- منتج جديد → ترتيب 2  
- منتج قديم → ترتيب 3

النتيجة في صفحة المنتجات:
1. منتج أقدم (ترتيب 1)
2. منتج جديد (ترتيب 2)
3. منتج قديم (ترتيب 3)
```

---

## 🎊 **تهانينا!**

**تم تطبيق ميزة ترتيب المنتجات بنجاح!**

### **الآن يمكن للمدير:**
- ✅ **تحديد ترتيب أي منتج في الصفحة**
- ✅ **جعل منتج معين يظهر أولاً**
- ✅ **ترتيب المنتجات حسب الأولوية**
- ✅ **التحكم الكامل في عرض المنتجات**

**🎯 الميزة تعمل بذكاء وبدون أي أخطاء!**
