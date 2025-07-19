# استخدام Node.js 18 LTS
FROM node:18-alpine

# إعداد مجلد العمل
WORKDIR /app

# نسخ ملفات package.json أولاً للاستفادة من Docker cache
COPY backend/package*.json ./

# تثبيت التبعيات
RUN npm ci --only=production && npm cache clean --force

# نسخ باقي الملفات
COPY backend/ ./

# إنشاء مستخدم غير root للأمان
RUN addgroup -g 1001 -S nodejs && \
    adduser -S montajati -u 1001

# تغيير ملكية الملفات
RUN chown -R montajati:nodejs /app
USER montajati

# كشف المنفذ
EXPOSE 3003

# فحص الصحة
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3003/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# تشغيل التطبيق
CMD ["npm", "start"]
