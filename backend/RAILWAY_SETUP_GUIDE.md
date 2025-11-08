# دليل إعداد Railway - Railway Setup Guide

## المشكلة الحالية - Current Problem

الخادم على Railway يعمل بشكل صحيح، لكن **مسارات API للطلبات لا تعمل** بسبب **عدم وجود متغيرات البيئة الصحيحة**.

### الأعراض - Symptoms:
- ✅ الصفحة الرئيسية `/` تعمل
- ✅ `/health` يعمل
- ✅ `/api/system/status` يعمل
- ❌ `/api/orders/user/:userPhone` لا يعمل (404)
- ❌ `/api/orders/user/:userPhone/counts` لا يعمل (404)

### السبب - Root Cause:
ملف `routes/orders.js` يحتاج إلى متغيرات البيئة التالية:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

إذا لم تكن هذه المتغيرات موجودة، سيفشل تحميل الملف بالكامل، مما يؤدي إلى عدم تسجيل المسارات.

---

## الحل - Solution

### الخطوة 1: فتح لوحة تحكم Railway

1. اذهب إلى: https://railway.app/
2. سجل الدخول
3. افتح مشروع `montajati-official-backend-production`

### الخطوة 2: إضافة متغيرات البيئة

1. اضغط على **Variables** في القائمة الجانبية
2. أضف المتغيرات التالية **واحدة تلو الأخرى**:

#### متغيرات Supabase (CRITICAL - يجب إضافتها):

```
SUPABASE_URL=https://fqdhskaolzfavapmqodl.supabase.co
```

```
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAwODE3MjYsImV4cCI6MjA2NTY1NzcyNn0.tRHMAogrSzjRwSIJ9-m0YMoPhlHeR6U8kfob0wyvf_I
```

```
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZGhza2FvbHpmYXZhcG1xb2RsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MDA4MTcyNiwiZXhwIjoyMDY1NjU3NzI2fQ.6G7ETs4PkK9WynRgVeZ-F_DPEf1BjaLq1-6AGeSHfIg
```

```
DATABASE_URL=postgresql://postgres:Mustfaabd2006@db.fqdhskaolzfavapmqodl.supabase.co:5432/postgres
```

#### متغيرات Firebase (للإشعارات):

```
FIREBASE_PROJECT_ID=montajati-app-7767d
```

```
FIREBASE_PRIVATE_KEY_ID=794f7262dae5875cadeab84bf2f7a62783f4bb41
```

```
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDOb4h0+x69k0IE\n2NUBJ8DAsN1KEqdc5J++V7nq9rfFsOUcWd3yCpMbvP3qADVkB9/N6q7PxPFkfwLM\nfT5fkATDcD+kXBnehAeWfRhxKhXgunHJ+3SlChnd/8vrve3+sgKiL/ymhiIJiGR2\nKajlrk8PUdOhr7KQ6WYRhh9jZWcHe1fPUO6v80gTU0lgJ05uutzzbZjPFE6Tmh+N\tfewoAAEUH4GrzsDXnuMD5oa8kcKBgPbiLfTycpLlgf5/SPbn53uvUjYt1kf2PPU\nfM6p/5UPGHGwWUlBSyutULWLO/Qav7+EpsyJCeB+xbBYpxNXqPeTn2A+8kKHKQ+m\nk+4PdPlJAgMBAAECggEAH87Lpcqzt94ixABtAZqQdqBJ2In7Q7LucjOuL+gH9OwG\nwVGPgyXh+Nor/Yw+rcUQ1PeeK+FamHOBiOSbYbodIcf/5mFSkxig2q03wOgNKu1P\nbyHRnURrK+uoDhDbxOzEvxzJvxbX08QyRoqwvYMYJ3IiO72ItA9ibLzPxU7wixRN\nCKDn1u52OJF94s6PnbXahRzwMgfo6rC8qRSiaDJwqISCuIUSewImWFJqGZWJLcRP\nOvSvdz85+ZpRQwxL5tYpjSXhQf6SWaNr28epFIQ3p13PzfZD+kqUN2g07+hZAccU\n2dPerED2Uo5cKzL/eR4NJP9h9gpdfx+5YUJAGRddIQKBgQD9zfMpHx/lMU2eBQeZ\nO9ntRfr451i6liW5arwxB080W4/9tGOfLUuifV/yWp/ZpnutkIFrGYv5+dG8nXY0\nybbYaoBSWCVAquFUxl4FUOP84aNP2IfaUgrTeVPF5OrkqctojtBt9sI6kUNTNrAj\nHOO6Jvj5RZC1Yr8PojSEcleuHQKBgQDQOK9XV18YRcMvof7Xap1k0/H1KcvUayJg\nt0zXOGDYxFsDT+rkfeKLUUpw8PSbceb/QSS/XnOHLzsE5nNjm5ELmxGm88XA1ivB\nwZ8YIt+OweEMp6X7eC+zeBJS+WLvccNyKjIHJ/b3A6YxSSDnTYrsuqsx2hbGpwuH\nA7kSa8tAHQKBgGi0t1VGpuTp4yiG0Kyx2WUe0rwuzRck7GlDFGJxroZeI9g5vEOl\n7ycY7CVSp9Gl8i4XiJzDjFDTdGiI2YRLl2hO/6N5A91a4d0UfSNaTMQ93h8JqHo0\nEI1P53SjzRgKyITZLjm/bD+3P/wrepzxxS09+Mb1oQ6Dr2jmtR3TAkMtAoGALsLs\nLdNDWfIg2Yup7brVyhUHG6XdTsEYoVvI9/SDW2sNfXrvJ41V2S/SZfbXGCnGVMDO\nfeO6Uju7J2iRtWb0dgTHPBU27g2rGgJftk3uouLLpcnorsbY/5cRlmzHWTrVR8hO\nH+lLv0GkiyD/MLLrZiqt065Euyw8nH+rioWGyckCgYEApZpYy0ZjboePNtE5t9t/\n8tYZ4cxolzm0nUrcdfUnqhChnWEzoy7AAYh9uCRBZXzq0gUoqt0MOprB89dVKrJb\n0xzir/9ZRPXGRdhnegrpRmxPrfH3WLNy03KMexjQ5vWdj0RmtSi31M8GTBzVwYkZ\nGeST/2d6kivlQhQ8Sr86HYg=\n-----END PRIVATE KEY-----"
```

```
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@montajati-app-7767d.iam.gserviceaccount.com
```

```
FIREBASE_CLIENT_ID=106253771612039775188
```

#### متغيرات أخرى:

```
JWT_SECRET=your_super_secret_jwt_key_here_change_this_in_production
```

```
JWT_EXPIRES_IN=7d
```

```
PORT=3002
```

```
NODE_ENV=production
```

```
TELEGRAM_BOT_TOKEN=7080610051:AAFdeYDMHDKkYgRrRNo_IBsdm0Qa5fezvRU
```

```
TELEGRAM_CHAT_ID=-1002729717960
```

```
LOW_STOCK_THRESHOLD=5
```

```
TELEGRAM_SUPPORT_BOT_TOKEN=7080610051:AAFdeYDMHDKkYgRrRNo_IBsdm0Qa5fezvRU
```

```
TELEGRAM_SUPPORT_CHAT_ID=6698779959
```

```
WASEET_USERNAME=محمد@mustfaabd
```

```
WASEET_PASSWORD=mustfaabd2006@
```

```
NOTIFICATIONS_ENABLED=true
```

### الخطوة 3: إعادة نشر التطبيق

بعد إضافة جميع المتغيرات، سيقوم Railway تلقائياً بإعادة نشر التطبيق.

انتظر حتى يكتمل النشر (حوالي 2-3 دقائق).

### الخطوة 4: التحقق من النجاح

بعد اكتمال النشر، اختبر المسارات:

```bash
# اختبار 1: الصفحة الرئيسية
curl https://montajati-official-backend-production.up.railway.app/

# اختبار 2: عدادات الطلبات
curl https://montajati-official-backend-production.up.railway.app/api/orders/user/07511111111/counts

# اختبار 3: جلب الطلبات
curl "https://montajati-official-backend-production.up.railway.app/api/orders/user/07511111111?page=0&limit=5"
```

إذا نجحت جميع الاختبارات، فقد تم حل المشكلة! ✅

---

## ملاحظات مهمة

1. **لا تشارك متغيرات البيئة مع أي شخص** - هذه معلومات حساسة
2. **تأكد من نسخ المتغيرات بالكامل** - خاصة `FIREBASE_PRIVATE_KEY` الذي يحتوي على `\n`
3. **Railway يدعم المتغيرات متعددة الأسطر** - لكن تأكد من استخدام علامات الاقتباس المزدوجة `"` حول القيمة

---

## استكشاف الأخطاء

### إذا استمرت المشكلة:

1. **تحقق من Logs**:
   - اذهب إلى Railway Dashboard
   - اضغط على **Deployments**
   - اضغط على آخر deployment
   - اضغط على **View Logs**
   - ابحث عن أي أخطاء تتعلق بـ Supabase

2. **تحقق من المتغيرات**:
   - اذهب إلى **Variables**
   - تأكد من وجود `SUPABASE_URL` و `SUPABASE_SERVICE_ROLE_KEY`
   - تأكد من عدم وجود مسافات زائدة في القيم

3. **أعد النشر يدوياً**:
   - اذهب إلى **Deployments**
   - اضغط على **Redeploy**

---

## الدعم

إذا واجهت أي مشاكل، تحقق من:
- Railway Logs
- Supabase Dashboard
- Firebase Console

