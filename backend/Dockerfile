# استخدام Node.js 20 لحل مشكلة cheerio
FROM node:20-alpine

# إنشاء مجلد العمل
WORKDIR /app

# نسخ package files
COPY package*.json ./

# تثبيت dependencies
RUN npm ci --only=production && npm cache clean --force

# نسخ باقي الملفات
COPY . .

# إنشاء مستخدم غير root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S montajati -u 1001 && \
    chown -R montajati:nodejs /app

# التبديل للمستخدم الجديد
USER montajati

# تعريف المنفذ
EXPOSE 3002

# أمر البدء
CMD ["node", "official_montajati_server.js"]
