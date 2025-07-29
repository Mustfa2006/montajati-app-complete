const axios = require('axios');
const FormData = require('form-data');

/**
 * خدمة API الوسيط الرسمية حسب التوثيق المحدث
 * URL: https://api.alwaseet-iq.net/v1/merchant/login
 * Method: POST
 * Content-Type: multipart/form-data
 */
class OfficialWaseetAPI {
  constructor(username, password) {
    this.username = username;
    this.password = password;
    this.baseUrl = 'https://api.alwaseet-iq.net';
    this.token = null;
    this.tokenExpiry = null;
    this.timeout = 30000;
  }

  /**
   * تسجيل الدخول حسب API الرسمي
   * POST /v1/merchant/login
   * Content-Type: multipart/form-data
   */
  async authenticate() {
    try {
      // التحقق من صحة التوكن الحالي
      if (this.isTokenValid()) {
        console.log('✅ استخدام التوكن الحالي الصالح');
        return this.token;
      }

      console.log('🔐 تسجيل الدخول باستخدام API الرسمي...');
      console.log(`👤 اسم المستخدم: ${this.username}`);

      // إعداد البيانات حسب التوثيق الرسمي - multipart/form-data
      const formData = new FormData();
      formData.append('username', this.username);
      formData.append('password', this.password);

      const loginUrl = `${this.baseUrl}/v1/merchant/login`;
      console.log(`🔗 URL: ${loginUrl}`);

      const response = await axios.post(loginUrl, formData, {
        headers: {
          ...formData.getHeaders(), // للحصول على Content-Type الصحيح
          'User-Agent': 'Montajati-App/2.2.0'
        },
        timeout: this.timeout,
        validateStatus: (status) => status < 500 // قبول حتى 4xx للتحقق
      });

      console.log(`📊 كود الاستجابة: ${response.status}`);
      console.log(`📄 بيانات الاستجابة:`, response.data);

      // معالجة الاستجابة حسب التوثيق الرسمي
      if (response.status === 200 && response.data) {
        const responseData = response.data;
        
        // التحقق من نجاح العملية حسب التوثيق
        if (responseData.status === true && responseData.errNum === 'S000') {
          // استخراج التوكن من البيانات
          if (responseData.data && responseData.data.token) {
            this.token = responseData.data.token;
            this.tokenExpiry = Date.now() + (30 * 60 * 1000); // صالح لمدة 30 دقيقة
            
            console.log(`✅ تم تسجيل الدخول بنجاح!`);
            console.log(`🎫 التوكن: ${this.token.substring(0, 20)}...`);
            console.log(`📝 رسالة النجاح: ${responseData.msg}`);
            
            return this.token;
          } else {
            throw new Error('لم يتم العثور على التوكن في الاستجابة');
          }
        } else {
          // معالجة الأخطاء حسب التوثيق
          const errorCode = responseData.errNum || 'غير محدد';
          const errorMessage = responseData.msg || 'خطأ غير معروف';
          throw new Error(`فشل تسجيل الدخول - كود الخطأ: ${errorCode}, الرسالة: ${errorMessage}`);
        }
      } else {
        throw new Error(`استجابة غير متوقعة من الخادم: ${response.status}`);
      }

    } catch (error) {
      console.error('❌ فشل تسجيل الدخول:', error.message);
      
      // طباعة تفاصيل الخطأ للتشخيص
      if (error.response) {
        console.error(`📊 كود الاستجابة: ${error.response.status}`);
        console.error(`📄 بيانات الخطأ:`, error.response.data);
      }
      
      throw new Error(`فشل في تسجيل الدخول: ${error.message}`);
    }
  }

  /**
   * التحقق من صحة التوكن
   */
  isTokenValid() {
    return this.token && this.tokenExpiry && Date.now() < this.tokenExpiry;
  }

  /**
   * جلب حالات الطلبات (سيتم تطويرها لاحقاً)
   */
  async getOrderStatuses() {
    try {
      // التأكد من تسجيل الدخول
      const token = await this.authenticate();

      console.log('📊 جلب حالات الطلبات...');
      
      // هنا سيتم إضافة API endpoint لجلب الحالات
      // بانتظار توضيح من شركة الوسيط
      
      return {
        success: true,
        message: 'تم تسجيل الدخول بنجاح - بانتظار API endpoint للحالات',
        token: token
      };

    } catch (error) {
      console.error('❌ فشل جلب حالات الطلبات:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * إعادة تعيين التوكن
   */
  resetToken() {
    this.token = null;
    this.tokenExpiry = null;
    console.log('🔄 تم إعادة تعيين التوكن');
  }
}

module.exports = OfficialWaseetAPI;
