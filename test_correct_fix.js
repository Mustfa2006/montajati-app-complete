const axios = require('axios');

async function testCorrectFix() {
  console.log('🎯 === اختبار الإصلاح الصحيح ===\n');
  console.log('🔧 فقط الحالة الصحيحة يجب أن ترسل للوسيط\n');
  console.log('✅ الحالة المؤهلة: ID: 3 - "قيد التوصيل الى الزبون (في عهدة المندوب)"\n');

  const baseURL = 'https://montajati-official-backend-production.up.railway.app';
  
  const testCases = [
    // الحالة الوحيدة المؤهلة
    { 
      status: '3', 
      description: 'الرقم 3 (يجب أن يتحول ويرسل للوسيط)', 
      shouldSendToWaseet: true,
      expectedStatus: 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    },
    { 
      status: 'قيد التوصيل الى الزبون (في عهدة المندوب)', 
      description: 'النص العربي الكامل (يجب أن يرسل للوسيط)', 
      shouldSendToWaseet: true,
      expectedStatus: 'قيد التوصيل الى الزبون (في عهدة المندوب)'
    },
    
    // الحالات التي لا يجب أن ترسل للوسيط
    { 
      status: 'active', 
      description: 'حالة نشط (لا يجب أن ترسل للوسيط)', 
      shouldSendToWaseet: false,
      expectedStatus: 'active'
    },
    { 
      status: 'cancelled', 
      description: 'حالة ملغي (لا يجب أن ترسل للوسيط)', 
      shouldSendToWaseet: false,
      expectedStatus: 'cancelled'
    },
    { 
      status: 'in_delivery', 
      description: 'حالة in_delivery (لا يجب أن ترسل للوسيط)', 
      shouldSendToWaseet: false,
      expectedStatus: 'in_delivery'
    }
  ];
  
  let correctResults = 0;
  let totalTests = testCases.length;
  
  try {
    console.log('⏰ انتظار 10 ثوان للتأكد من تطبيق التغييرات...\n');
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    for (const [index, testCase] of testCases.entries()) {
      console.log(`\n🧪 اختبار ${index + 1}: ${testCase.description}`);
      console.log(`   📝 الحالة المرسلة: "${testCase.status}"`);
      console.log(`   🔄 متوقع التحويل إلى: "${testCase.expectedStatus}"`);
      console.log(`   📦 متوقع الإرسال للوسيط: ${testCase.shouldSendToWaseet ? '✅ نعم' : '❌ لا'}`);
      
      // إنشاء طلب جديد لكل اختبار
      const newOrderData = {
        customer_name: `اختبار صحيح ${index + 1}`,
        primary_phone: '07901234567',
        customer_address: 'بغداد - الكرخ - اختبار صحيح',
        province: 'بغداد',
        city: 'الكرخ',
        subtotal: 25000,
        delivery_fee: 5000,
        total: 30000,
        profit: 5000,
        profit_amount: 5000,
        status: 'active',
        user_id: 'bba1fc61-3db9-4c5f-8b19-d8689251990d',
        user_phone: '07503597589',
        order_number: `ORD-CORRECT-${index + 1}-${Date.now()}`,
        notes: `اختبار صحيح: ${testCase.description}`
      };
      
      const createResponse = await axios.post(`${baseURL}/api/orders`, newOrderData, {
        headers: {
          'Content-Type': 'application/json'
        },
        timeout: 30000
      });
      
      if (createResponse.data.success) {
        const orderId = createResponse.data.data.id;
        console.log(`   📦 طلب الاختبار: ${orderId}`);
        
        // تحديث الحالة
        const updateData = {
          status: testCase.status,
          notes: `اختبار صحيح: ${testCase.description}`,
          changedBy: 'correct_test'
        };
        
        console.log(`   📤 إرسال تحديث الحالة...`);
        
        try {
          const updateResponse = await axios.put(
            `${baseURL}/api/orders/${orderId}/status`,
            updateData,
            {
              headers: {
                'Content-Type': 'application/json'
              },
              timeout: 60000
            }
          );
          
          if (updateResponse.data.success) {
            console.log(`   ✅ تم تحديث الحالة بنجاح`);
            
            // انتظار قصير ثم فحص النتيجة
            await new Promise(resolve => setTimeout(resolve, 10000));
            
            const ordersResponse = await axios.get(`${baseURL}/api/orders`, { timeout: 15000 });
            const updatedOrder = ordersResponse.data.data.find(o => o.id === orderId);
            
            if (updatedOrder) {
              console.log(`   📋 النتيجة الفعلية:`);
              console.log(`      📊 الحالة في قاعدة البيانات: "${updatedOrder.status}"`);
              console.log(`      🔄 هل تطابق المتوقع؟ ${updatedOrder.status === testCase.expectedStatus ? '✅ نعم' : '❌ لا'}`);
              
              const hasWaseetId = updatedOrder.waseet_order_id && updatedOrder.waseet_order_id !== 'null';
              console.log(`      🆔 معرف الوسيط: ${updatedOrder.waseet_order_id || 'غير محدد'}`);
              console.log(`      📦 تم الإرسال للوسيط: ${hasWaseetId ? '✅ نعم' : '❌ لا'}`);
              
              // فحص صحة النتيجة
              const statusCorrect = updatedOrder.status === testCase.expectedStatus;
              const waseetCorrect = hasWaseetId === testCase.shouldSendToWaseet;
              
              if (statusCorrect && waseetCorrect) {
                console.log(`   🎉 النتيجة صحيحة تماماً!`);
                correctResults++;
              } else {
                console.log(`   ❌ النتيجة غير صحيحة:`);
                if (!statusCorrect) {
                  console.log(`      - الحالة خاطئة: متوقع "${testCase.expectedStatus}" لكن حصلت على "${updatedOrder.status}"`);
                }
                if (!waseetCorrect) {
                  console.log(`      - إرسال الوسيط خاطئ: متوقع ${testCase.shouldSendToWaseet ? 'إرسال' : 'عدم إرسال'} لكن ${hasWaseetId ? 'تم الإرسال' : 'لم يتم الإرسال'}`);
                }
              }
              
              if (hasWaseetId && testCase.shouldSendToWaseet) {
                console.log(`      🔗 QR ID: ${updatedOrder.waseet_order_id}`);
                
                // فحص رابط الوسيط
                if (updatedOrder.waseet_data) {
                  try {
                    const waseetData = JSON.parse(updatedOrder.waseet_data);
                    if (waseetData.waseetResponse && waseetData.waseetResponse.data && waseetData.waseetResponse.data.qr_link) {
                      console.log(`      🔗 رابط الوسيط: ${waseetData.waseetResponse.data.qr_link}`);
                    }
                  } catch (e) {
                    // تجاهل أخطاء التحليل
                  }
                }
              }
            }
          } else {
            console.log(`   ❌ فشل في تحديث الحالة: ${updateResponse.data.error}`);
          }
          
        } catch (error) {
          console.log(`   ❌ خطأ في تحديث الحالة: ${error.message}`);
        }
      } else {
        console.log(`   ❌ فشل في إنشاء طلب الاختبار`);
      }
    }
    
    console.log('\n📊 === النتائج النهائية ===');
    console.log(`✅ نتائج صحيحة: ${correctResults} من ${totalTests}`);
    console.log(`❌ نتائج خاطئة: ${totalTests - correctResults} من ${totalTests}`);
    
    const successRate = (correctResults / totalTests) * 100;
    console.log(`📈 معدل النجاح: ${successRate.toFixed(1)}%`);
    
    if (correctResults === totalTests) {
      console.log('\n🎉 === الإصلاح مثالي! ===');
      console.log('✅ جميع الاختبارات نجحت');
      console.log('✅ فقط الحالة الصحيحة ترسل للوسيط');
      console.log('✅ باقي الحالات لا ترسل للوسيط');
      
      console.log('\n🎊 === تهانينا! ===');
      console.log('🎯 النظام يعمل بالطريقة الصحيحة تماماً');
      console.log('📱 يمكنك الآن استخدام التطبيق:');
      console.log('   1. أنشئ طلب جديد');
      console.log('   2. غير حالته إلى الرقم "3" أو النص الكامل');
      console.log('   3. ستظهر معرف الوسيط فقط للحالة الصحيحة');
      console.log('   4. باقي الحالات لن ترسل للوسيط');
      
    } else if (correctResults >= totalTests * 0.8) {
      console.log('\n🔧 === الإصلاح جيد جداً ===');
      console.log('✅ معظم الاختبارات نجحت');
      console.log('⚠️ قد تحتاج لتحسينات طفيفة');
    } else {
      console.log('\n❌ === الإصلاح يحتاج مراجعة ===');
      console.log('❌ عدد كبير من الاختبارات فشل');
      console.log('🔍 تحتاج لمزيد من التشخيص');
    }
    
    console.log('\n🎯 === الخلاصة ===');
    console.log('الحالة الوحيدة المؤهلة للإرسال للوسيط:');
    console.log('🔹 ID: 3');
    console.log('🔹 النص: "قيد التوصيل الى الزبون (في عهدة المندوب)"');
    console.log('🔹 جميع الحالات الأخرى لا ترسل للوسيط');
    
  } catch (error) {
    console.error('❌ خطأ في اختبار الإصلاح الصحيح:', error.message);
  }
}

testCorrectFix();
