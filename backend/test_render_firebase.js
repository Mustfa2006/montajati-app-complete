// فحص سريع لبيانات Firebase من Render
const renderData = `{"type":"service_account","project_id":"montajati-app-7767d","private_key_id":"ce43ffe8abd4ffc11eaae853291626b3e11ccb6","private_key":"-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCBuV877tzoEfiBVnjmxp/XMPjGOtmBjR\\nW3BynNpoM26yb3r3nrLr+JoNXzmfR11y9sOuz+EAvcPCVP5H\\nCPiD/5t4B+Xnp5vCFTCpUkZIek4DppRCaD\\nqbDPhsUSvCD9pRJ/Ks/VUPxLXHGHqX\\nXTI5mTSTvc16/T6SugZsDGeQijy+U791WHtKt0nadckiDeHU3Po/\\nujp+2ezgjdwM\\nZ9TqO31PXMk/oQNnIAdcJ65NhGo1lW/CqDcRqOCuCoI7CFnVqKVbDhv7I/DqLxL\\nVhkRG\\n+7uBGilsH1+ZUv++nlnQIIvRlnsfevS4LtqqRRPBCCNaJHHamFdOwngIRhG6+USBxSnr7nzlw51ud4PxJoJB\\neyNZ3ExnRGT7UdGbMNK+urcgBPBUuFR31Ud9bTmIDYiPnZWwCOKPT\\nnNnELZib27\\n+S3dywauo1g8jahJAPxPtponHdRPBF1Kf+Rys2fF0e11sSLLfMslBR\\nnpqz3M3BgV42xBDTVhPkFtJDjGCOL\\nNMzMSS/mh1znAdKBgQDy3vuDi11YG8nXbITE\\nnFSIaPIR412U96qrZdNwAui5wi1MHv13pOzNOE783YoXKmwYl\\naCi0ZYHf2aeaJdvgD\\nSvMAQGENi4mXWGfvdo+tVYYwajezfQbmBqe9F5cU/SkeXTAFJd5\\nXnXGMQvGekBXPjwSy2wvT0xpAOKBgQDLqGedvI5/f6ZBKqKdIWXOzDGeAzoa/\\nlnD9faV1fyZJhYLx\\nL4oemCwayOXu9POhttIrCJtNt1MYbo6Uzs2JnkkbDj+LqYn91j2yOAMgzhnVUZJO++vG7eORhuMdFomF\\n5OenhgzyHZnSF125IH1i0aEU/SejOc\\njnJt3q3j/oOKBgGAoTkheTiD4XxXkKk9H6BI23kT6TSUkqiKE5kN\\nTxj4XYAf9g1nYGbmMNK+4kvY3UdgP9yMkBRXmrCKUnMcrZJ+6KTieWi133nJBkj5/8Z5hXf\\nlnL7b9\\nQ5sYGjm+yZcv1qm9OCFGmYTWe6VATwmCm8P4kIZfn/rn711goBAAb1/9\\nJ09k+90S1FnQDyf\\nKnw5L06ji5wJDupZbeOq6THDcKMeo8r6TNcef/eo0\\nwaomNVjCzVBOefeYLkcZO0@CkmMDP7PIIFDdif\\n1kCgGhPbGRIYfJvX8nSvMAQGENi4mXWGfvdo+tVYYwajezfQbmBqe9F5cU/SkeXTAFJd5\\nRFSBD+\\nhHkuT9jfZI7L/2Lx4Y3G6XMeYIwTwcImcUJgFEIMM7IgfI74j5xoznmIFARaTGGu\\nOJ/0FWLzDz\\nQiTuUeVeqIhNSFpDy1ZnbS/4KeaRdLThY/HGEDT50r6X+TFk/JuH2\\nJ6F5BW5lMXuykKmLMbDho=\\n-----END PRIVATE KEY-----\\n","client_email":"firebase-adminsdk-fbsyc4@montajati-app-7767d.iam.gserviceaccount.com","client_id":"106253771612039775188","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsyc4%40montajati-app-7767d.iam.gserviceaccount.com","universe_domain":"googleapis.com"}`;

console.log('🔍 فحص بيانات Firebase من Render...\n');

try {
  // تحليل JSON
  const serviceAccount = JSON.parse(renderData);
  
  console.log('✅ تم تحليل JSON بنجاح');
  console.log('📋 معلومات Service Account:');
  console.log(`   Project ID: ${serviceAccount.project_id}`);
  console.log(`   Client Email: ${serviceAccount.client_email}`);
  console.log(`   Type: ${serviceAccount.type}`);
  console.log(`   Private Key ID: ${serviceAccount.private_key_id?.substring(0, 8)}...`);
  
  // فحص Private Key
  const privateKey = serviceAccount.private_key;
  console.log('\n🔑 فحص Private Key:');
  console.log(`   يبدأ بـ BEGIN: ${privateKey.startsWith('-----BEGIN PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`   ينتهي بـ END: ${privateKey.endsWith('-----END PRIVATE KEY-----') ? '✅' : '❌'}`);
  console.log(`   يحتوي على \\n: ${privateKey.includes('\\n') ? '✅' : '❌'}`);
  console.log(`   طول المفتاح: ${privateKey.length} حرف`);
  
  // تحويل \\n إلى أسطر جديدة حقيقية
  const fixedPrivateKey = privateKey.replace(/\\n/g, '\n');
  console.log(`   بعد إصلاح الأسطر: ${fixedPrivateKey.split('\n').length} سطر`);
  
  // اختبار Firebase
  console.log('\n🔥 اختبار تهيئة Firebase...');
  
  const admin = require('firebase-admin');
  
  // حذف التهيئة السابقة
  if (admin.apps.length > 0) {
    admin.apps.forEach(app => app.delete());
  }
  
  // تهيئة Firebase
  const fixedServiceAccount = {
    ...serviceAccount,
    private_key: fixedPrivateKey
  };
  
  admin.initializeApp({
    credential: admin.credential.cert(fixedServiceAccount),
    projectId: serviceAccount.project_id
  });
  
  console.log('✅ تم تهيئة Firebase بنجاح!');
  
  // اختبار Messaging
  const messaging = admin.messaging();
  console.log('✅ تم تهيئة Firebase Messaging بنجاح!');
  
  console.log('\n🎉 جميع فحوصات Firebase نجحت!');
  console.log('✅ البيانات من Render صحيحة ومُعدة بشكل مثالي');
  
} catch (error) {
  console.error('❌ خطأ في فحص Firebase:', error.message);
  
  if (error.message.includes('JSON')) {
    console.log('\n🔧 مشكلة في تحليل JSON - تحقق من تنسيق البيانات');
  } else if (error.message.includes('private_key')) {
    console.log('\n🔧 مشكلة في Private Key - تحقق من تنسيق المفتاح');
  } else {
    console.log('\n🔧 مشكلة في تهيئة Firebase - تحقق من صحة البيانات');
  }
}
