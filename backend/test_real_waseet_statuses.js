// ===================================
// اختبار جلب الحالات الحقيقية من شركة الوسيط
// Test Real Waseet Status Fetching
// ===================================

const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

async function testRealWaseetStatuses() {
  try {
    console.log('🔍 اختبار جلب الحالات الحقيقية من شركة الوسيط...\n');

    // إعداد Supabase
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    // إعدادات شركة الوسيط
    const waseetConfig = {
      baseUrl: process.env.ALMASEET_BASE_URL || 'https://api.alwaseet-iq.net',
      username: process.env.WASEET_USERNAME,
      password: process.env.WASEET_PASSWORD
    };

    // الحالات المطلوبة من شركة الوسيط
    const expectedStatuses = {
      24: "تم تغيير محافظة الزبون",
      42: "تغيير المندوب", 
      25: "لا يرد",
      26: "لا يرد بعد الاتفاق",
      27: "مغلق",
      28: "مغلق بعد الاتفاق",
      3: "قيد التوصيل الى الزبون (في عهدة المندوب)",
      36: "الرقم غير معرف",
      37: "الرقم غير داخل في الخدمة",
      41: "لا يمكن الاتصال بالرقم",
      29: "مؤجل",
      30: "مؤجل لحين اعادة الطلب لاحقا",
      31: "الغاء الطلب",
      32: "رفض الطلب",
      33: "مفصول عن الخدمة",
      34: "طلب مكرر",
      35: "مستلم مسبقا",
      38: "العنوان غير دقيق",
      39: "لم يطلب",
      40: "حظر المندوب"
    };

    console.log('📋 الحالات المطلوبة من شركة الوسيط:');
    Object.entries(expectedStatuses).forEach(([id, status]) => {
      console.log(`   ID: ${id} - "${status}"`);
    });

    // 1. تسجيل الدخول
    console.log('\n🔐 تسجيل الدخول في شركة الوسيط...');
    const loginData = new URLSearchParams({
      username: waseetConfig.username,
      password: waseetConfig.password
    });

    const loginResponse = await axios.post(
      `${waseetConfig.baseUrl}/merchant/login`,
      loginData,
      {
        timeout: 15000,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        maxRedirects: 0,
        validateStatus: () => true
      }
    );

    if (loginResponse.status !== 302 && loginResponse.status !== 303) {
      throw new Error(`فشل تسجيل الدخول: ${loginResponse.status}`);
    }

    const token = loginResponse.headers['set-cookie']?.join('; ') || '';
    console.log('✅ تم تسجيل الدخول بنجاح');

    // 2. جلب طلبات حقيقية للاختبار
    console.log('\n📋 جلب طلبات حقيقية من قاعدة البيانات...');
    const { data: orders, error } = await supabase
      .from('orders')
      .select('id, order_number, waseet_order_id, status, waseet_status')
      .not('waseet_order_id', 'is', null)
      .limit(10);

    if (error || !orders || orders.length === 0) {
      throw new Error('لا توجد طلبات للاختبار');
    }

    console.log(`✅ تم العثور على ${orders.length} طلب للاختبار`);

    // 3. اختبار طرق مختلفة لجلب الحالات
    const testMethods = [
      {
        name: 'جلب حالة طلب واحد',
        url: `${waseetConfig.baseUrl}/merchant/get_order_status`,
        method: 'GET'
      },
      {
        name: 'جلب تفاصيل الطلب',
        url: `${waseetConfig.baseUrl}/merchant/order_details`,
        method: 'GET'
      },
      {
        name: 'جلب قائمة الطلبات',
        url: `${waseetConfig.baseUrl}/merchant/orders`,
        method: 'GET'
      },
      {
        name: 'API جلب الطلبات',
        url: `${waseetConfig.baseUrl}/api/merchant/orders`,
        method: 'GET'
      },
      {
        name: 'جلب الحالات المتاحة',
        url: `${waseetConfig.baseUrl}/merchant/statuses`,
        method: 'GET'
      }
    ];

    const foundStatuses = new Set();
    const statusFormats = {
      byId: new Set(),
      byArabic: new Set(),
      byEnglish: new Set()
    };

    // 4. اختبار كل طريقة
    for (const method of testMethods) {
      console.log(`\n🔍 اختبار: ${method.name}`);
      console.log(`🌐 URL: ${method.url}`);

      try {
        // اختبار مع طلب محدد
        const testOrder = orders[0];
        const params = method.url.includes('get_order_status') || method.url.includes('order_details') 
          ? { order_id: testOrder.waseet_order_id, id: testOrder.waseet_order_id }
          : {};

        const response = await axios.get(method.url, {
          params,
          timeout: 15000,
          headers: {
            'Cookie': token,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          },
          validateStatus: () => true
        });

        console.log(`📊 رمز الحالة: ${response.status}`);

        if (response.status === 200) {
          console.log(`✅ نجح!`);
          
          // تحليل الاستجابة
          let responseData = response.data;
          
          if (typeof responseData === 'string') {
            // محاولة تحويل JSON إذا كان نص
            try {
              responseData = JSON.parse(responseData);
            } catch (e) {
              // إذا كان HTML، ابحث عن الحالات
              if (responseData.includes('<html>')) {
                console.log('📄 استجابة HTML - البحث عن الحالات...');
                
                // البحث عن الحالات في HTML
                Object.entries(expectedStatuses).forEach(([id, status]) => {
                  if (responseData.includes(status)) {
                    foundStatuses.add(status);
                    statusFormats.byArabic.add(status);
                    console.log(`✅ وجدت حالة: "${status}"`);
                  }
                  if (responseData.includes(`status_id="${id}"`)) {
                    foundStatuses.add(id);
                    statusFormats.byId.add(id);
                    console.log(`✅ وجدت ID: ${id}`);
                  }
                });
              }
            }
          }

          if (typeof responseData === 'object') {
            console.log('📊 استجابة JSON:');
            console.log(JSON.stringify(responseData, null, 2));
            
            // البحث عن الحالات في JSON
            const searchInObject = (obj, path = '') => {
              if (typeof obj === 'object' && obj !== null) {
                Object.entries(obj).forEach(([key, value]) => {
                  const currentPath = path ? `${path}.${key}` : key;
                  
                  if (typeof value === 'string') {
                    // البحث عن الحالات العربية
                    Object.entries(expectedStatuses).forEach(([id, status]) => {
                      if (value.includes(status)) {
                        foundStatuses.add(status);
                        statusFormats.byArabic.add(status);
                        console.log(`✅ وجدت حالة في ${currentPath}: "${status}"`);
                      }
                    });
                  } else if (typeof value === 'number') {
                    // البحث عن IDs
                    if (expectedStatuses[value.toString()]) {
                      foundStatuses.add(value.toString());
                      statusFormats.byId.add(value.toString());
                      console.log(`✅ وجدت ID في ${currentPath}: ${value}`);
                    }
                  } else if (typeof value === 'object') {
                    searchInObject(value, currentPath);
                  }
                });
              }
            };

            searchInObject(responseData);
          }

        } else {
          console.log(`❌ فشل: ${response.status}`);
        }

      } catch (error) {
        console.log(`❌ خطأ: ${error.message}`);
      }

      console.log('-'.repeat(60));
    }

    // 5. اختبار جلب حالة طلب محدد بطرق مختلفة
    console.log('\n🎯 اختبار جلب حالة طلب محدد بطرق مختلفة...');
    
    for (const order of orders.slice(0, 3)) {
      console.log(`\n📦 اختبار الطلب: ${order.order_number} (ID: ${order.waseet_order_id})`);
      
      const testUrls = [
        `${waseetConfig.baseUrl}/merchant/get_order_status?order_id=${order.waseet_order_id}`,
        `${waseetConfig.baseUrl}/merchant/order_details?id=${order.waseet_order_id}`,
        `${waseetConfig.baseUrl}/api/orders/${order.waseet_order_id}`,
        `${waseetConfig.baseUrl}/merchant/check_status/${order.waseet_order_id}`
      ];

      for (const url of testUrls) {
        try {
          const response = await axios.get(url, {
            timeout: 10000,
            headers: {
              'Cookie': token,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            },
            validateStatus: () => true
          });

          if (response.status === 200) {
            console.log(`✅ ${url} - نجح`);
            
            // تحليل الاستجابة للبحث عن الحالة
            let statusFound = false;
            const responseText = typeof response.data === 'string' ? response.data : JSON.stringify(response.data);
            
            Object.entries(expectedStatuses).forEach(([id, status]) => {
              if (responseText.includes(status) || responseText.includes(`"status_id":${id}`) || responseText.includes(`status_id="${id}"`)) {
                console.log(`   🎯 وجدت حالة: ID ${id} - "${status}"`);
                foundStatuses.add(status);
                statusFound = true;
              }
            });

            if (!statusFound) {
              console.log(`   📊 لم توجد حالة معروفة في الاستجابة`);
            }
          } else {
            console.log(`❌ ${url} - فشل (${response.status})`);
          }
        } catch (error) {
          console.log(`❌ ${url} - خطأ: ${error.message}`);
        }
      }
    }

    // 6. تقرير النتائج
    console.log('\n🎯 تقرير نتائج جلب الحالات الحقيقية:');
    console.log('=' * 80);

    console.log(`📊 إجمالي الحالات المطلوبة: ${Object.keys(expectedStatuses).length}`);
    console.log(`✅ الحالات الموجودة: ${foundStatuses.size}`);
    console.log(`📈 معدل التغطية: ${((foundStatuses.size / Object.keys(expectedStatuses).length) * 100).toFixed(1)}%`);

    console.log('\n📋 تفاصيل الحالات الموجودة:');
    if (foundStatuses.size > 0) {
      Array.from(foundStatuses).forEach((status, index) => {
        console.log(`   ${index + 1}. ${status}`);
      });
    } else {
      console.log('   ⚠️ لم يتم العثور على حالات');
    }

    console.log('\n📊 تنسيقات الحالات المكتشفة:');
    console.log(`🔢 بـ ID: ${statusFormats.byId.size} حالة`);
    console.log(`🔤 بالعربي: ${statusFormats.byArabic.size} حالة`);
    console.log(`🔤 بالإنجليزي: ${statusFormats.byEnglish.size} حالة`);

    // 7. توصيات للتطوير
    console.log('\n💡 توصيات للتطوير:');
    if (foundStatuses.size === 0) {
      console.log('🚨 يجب العثور على API الصحيح لجلب الحالات');
      console.log('🔍 جرب endpoints إضافية أو اتصل بالدعم التقني');
    } else if (foundStatuses.size < Object.keys(expectedStatuses).length / 2) {
      console.log('⚠️ تم العثور على بعض الحالات، يحتاج تحسين');
      console.log('🔧 طور النظام ليدعم التنسيقات المكتشفة');
    } else {
      console.log('✅ تم العثور على معظم الحالات');
      console.log('🚀 النظام جاهز للتطوير الكامل');
    }

    console.log('\n🎉 انتهى اختبار جلب الحالات الحقيقية!');

    return {
      total_expected: Object.keys(expectedStatuses).length,
      found_statuses: foundStatuses.size,
      coverage_rate: ((foundStatuses.size / Object.keys(expectedStatuses).length) * 100).toFixed(1),
      status_formats: statusFormats,
      found_list: Array.from(foundStatuses)
    };

  } catch (error) {
    console.error('❌ خطأ في اختبار جلب الحالات الحقيقية:', error.message);
    return {
      success: false,
      error: error.message
    };
  }
}

// تشغيل الاختبار
if (require.main === module) {
  testRealWaseetStatuses().then(report => {
    console.log('\n📊 ملخص سريع:');
    if (report.coverage_rate) {
      console.log(`🎯 معدل التغطية: ${report.coverage_rate}%`);
      console.log(`📊 حالات موجودة: ${report.found_statuses}/${report.total_expected}`);
    }
  }).catch(error => {
    console.error('❌ خطأ في تشغيل الاختبار:', error.message);
  });
}

module.exports = testRealWaseetStatuses;
