// نموذج المستخدم - User Model
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // المعلومات الأساسية
  name: {
    type: String,
    required: [true, 'الاسم مطلوب'],
    trim: true,
    minlength: [2, 'الاسم يجب أن يكون حرفين على الأقل'],
    maxlength: [50, 'الاسم لا يمكن أن يزيد عن 50 حرف']
  },
  
  email: {
    type: String,
    required: [true, 'البريد الإلكتروني مطلوب'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [
      /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/,
      'يرجى إدخال بريد إلكتروني صحيح'
    ]
  },
  
  password: {
    type: String,
    required: [true, 'كلمة المرور مطلوبة'],
    minlength: [8, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'],
    select: false // لا تُرجع كلمة المرور في الاستعلامات العادية
  },
  
  // معلومات إضافية
  phone: {
    type: String,
    trim: true
  },
  
  avatar: {
    type: String, // رابط الصورة في Cloudinary
    default: null
  },
  
  // إعدادات الحساب
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  
  // إحصائيات المستخدم
  totalProducts: {
    type: Number,
    default: 0
  },
  
  totalOrders: {
    type: Number,
    default: 0
  },
  
  totalSales: {
    type: Number,
    default: 0
  },
  
  // تواريخ مهمة
  lastLogin: {
    type: Date,
    default: null
  },
  
  passwordChangedAt: {
    type: Date,
    default: Date.now
  },
  
  // رموز التحقق
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  passwordResetToken: String,
  passwordResetExpires: Date,
  
}, {
  timestamps: true, // إضافة createdAt و updatedAt تلقائياً
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// فهرسة للبحث السريع (email فهرس فريد بالفعل من unique: true)
userSchema.index({ createdAt: -1 });

// تشفير كلمة المرور قبل الحفظ
userSchema.pre('save', async function(next) {
  // إذا لم تتغير كلمة المرور، تابع
  if (!this.isModified('password')) return next();
  
  try {
    // تشفير كلمة المرور
    this.password = await bcrypt.hash(this.password, 12);
    next();
  } catch (error) {
    next(error);
  }
});

// تحديث passwordChangedAt عند تغيير كلمة المرور
userSchema.pre('save', function(next) {
  if (!this.isModified('password') || this.isNew) return next();
  
  this.passwordChangedAt = Date.now() - 1000; // طرح ثانية للتأكد
  next();
});

// دالة للتحقق من كلمة المرور
userSchema.methods.correctPassword = async function(candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

// دالة للتحقق من تغيير كلمة المرور بعد إصدار JWT
userSchema.methods.changedPasswordAfter = function(JWTTimestamp) {
  if (this.passwordChangedAt) {
    const changedTimestamp = parseInt(
      this.passwordChangedAt.getTime() / 1000,
      10
    );
    return JWTTimestamp < changedTimestamp;
  }
  return false;
};

// دالة لإنشاء رمز إعادة تعيين كلمة المرور
userSchema.methods.createPasswordResetToken = function() {
  const resetToken = crypto.randomBytes(32).toString('hex');
  
  this.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');
  
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 دقائق
  
  return resetToken;
};

// دالة لإنشاء رمز تحقق البريد الإلكتروني
userSchema.methods.createEmailVerificationToken = function() {
  const verificationToken = crypto.randomBytes(32).toString('hex');
  
  this.emailVerificationToken = crypto
    .createHash('sha256')
    .update(verificationToken)
    .digest('hex');
  
  this.emailVerificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 ساعة
  
  return verificationToken;
};

// Virtual للحصول على عدد المنتجات
userSchema.virtual('productsCount', {
  ref: 'Product',
  localField: '_id',
  foreignField: 'owner',
  count: true
});

// Virtual للحصول على عدد الطلبات
userSchema.virtual('ordersCount', {
  ref: 'Order',
  localField: '_id',
  foreignField: 'customer',
  count: true
});

const User = mongoose.model('User', userSchema);

module.exports = User;
