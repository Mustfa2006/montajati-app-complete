const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

// إعداد Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-anon-key';
const supabase = createClient(supabaseUrl, supabaseKey);

// 📊 جلب الإحصائيات الحقيقية من قاعدة البيانات
router.get('/real-statistics', async (req, res) => {
  try {
    const { period = 'month' } = req.query;

    console.log(`🔄 جلب الإحصائيات الحقيقية للفترة: ${period}`);

    // جلب جميع الطلبات من قاعدة البيانات
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('*');

    if (ordersError) {
      console.error('خطأ في جلب الطلبات:', ordersError);
      return res.status(500).json({
        success: false,
        error: 'فشل في جلب الطلبات من قاعدة البيانات'
      });
    }

    console.log(`📊 تم جلب ${orders?.length || 0} طلب من قاعدة البيانات`);

    // تصفية الطلبات حسب الفترة
    const filteredOrders = filterOrdersByPeriod(orders || [], period);
    console.log(`🔍 تم تصفية ${filteredOrders.length} طلب للفترة المحددة`);

    // حساب الإحصائيات الحقيقية
    const statistics = calculateRealStatistics(filteredOrders);

    console.log('✅ تم حساب الإحصائيات الحقيقية بنجاح');
    console.log(`📈 إجمالي الطلبات: ${statistics.totalOrders}`);
    console.log(`💰 إجمالي الأرباح: ${statistics.totalProfits.toFixed(2)} د.ع`);

    res.json({
      success: true,
      period: period,
      statistics: statistics,
      totalOrders: statistics.totalOrders,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('خطأ في جلب الإحصائيات:', error);
    res.status(500).json({
      success: false,
      error: 'فشل في جلب الإحصائيات'
    });
  }
});

// 💾 حفظ الإحصائيات في قاعدة البيانات (محاكاة)
async function saveStatisticsToDatabase(statistics, period) {
  try {
    console.log(`💾 حفظ الإحصائيات للفترة: ${period}`);
    mockDatabase.statistics[period] = {
      ...statistics,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    console.log('✅ تم حفظ الإحصائيات بنجاح');
  } catch (error) {
    console.error('خطأ في حفظ الإحصائيات:', error);
  }
}

// 🧮 حساب الإحصائيات الحقيقية
function calculateRealStatistics(orders) {
  const statistics = {
    totalOrders: orders.length,
    activeOrders: 0,
    deliveredOrders: 0,
    inDeliveryOrders: 0,
    cancelledOrders: 0,
    totalProfits: 0,
    realizedProfits: 0,
    expectedProfits: 0,
    averageProfitPerOrder: 0,
    bestProduct: 'غير محدد',
    bestProductSales: 0,
    bestProductProfit: 0,
    ordersGrowth: 0,
    profitsGrowth: 0
  };

  // حساب عدد الطلبات حسب الحالة والأرباح
  const productSales = {};
  const productProfits = {};

  orders.forEach(order => {
    const status = order.status;
    const profit = parseFloat(order.profit || 0);
    const productName = order.product_name || 'منتج غير محدد';

    // عدد الطلبات حسب الحالة
    switch (status) {
      case 'active':
        statistics.activeOrders++;
        statistics.expectedProfits += profit;
        break;
      case 'in_delivery':
        statistics.inDeliveryOrders++;
        statistics.expectedProfits += profit;
        break;
      case 'delivered':
        statistics.deliveredOrders++;
        statistics.realizedProfits += profit;
        break;
      case 'cancelled':
      case 'rejected':
        statistics.cancelledOrders++;
        break;
    }

    // إجمالي الأرباح
    statistics.totalProfits += profit;

    // تتبع مبيعات المنتجات
    if (!productSales[productName]) {
      productSales[productName] = 0;
      productProfits[productName] = 0;
    }
    productSales[productName]++;
    productProfits[productName] += profit;
  });

  // حساب متوسط الربح لكل طلب
  statistics.averageProfitPerOrder = statistics.totalOrders > 0 
    ? statistics.totalProfits / statistics.totalOrders 
    : 0;

  // العثور على أفضل منتج
  let bestProduct = 'غير محدد';
  let maxSales = 0;
  for (const [product, sales] of Object.entries(productSales)) {
    if (sales > maxSales) {
      maxSales = sales;
      bestProduct = product;
    }
  }
  
  statistics.bestProduct = bestProduct;
  statistics.bestProductSales = maxSales;
  statistics.bestProductProfit = productProfits[bestProduct] || 0;

  return statistics;
}

// 📅 تصفية الطلبات حسب الفترة
function filterOrdersByPeriod(orders, period) {
  const now = new Date();
  let startDate;

  switch (period) {
    case 'day':
      startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      break;
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      break;
    case 'month':
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      break;
    case '3months':
      startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      break;
    case 'year':
      startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
      break;
    default:
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }

  return orders.filter(order => {
    const orderDate = new Date(order.created_at);
    return orderDate >= startDate;
  });
}

// 📈 جلب الإحصائيات المحفوظة من قاعدة البيانات (محاكاة)
router.get('/saved-statistics/:period', async (req, res) => {
  try {
    const { period } = req.params;

    console.log(`📈 جلب الإحصائيات المحفوظة للفترة: ${period}`);

    const savedStats = mockDatabase.statistics[period];

    if (!savedStats) {
      return res.status(404).json({ error: 'لا توجد إحصائيات محفوظة لهذه الفترة' });
    }

    res.json({
      success: true,
      statistics: savedStats
    });

  } catch (error) {
    console.error('خطأ في جلب الإحصائيات المحفوظة:', error);
    res.status(500).json({ error: 'فشل في جلب الإحصائيات المحفوظة' });
  }
});

// 🔄 تحديث الإحصائيات لجميع الفترات (محاكاة)
router.post('/update-all-statistics', async (req, res) => {
  try {
    const periods = ['day', 'week', 'month', '3months', 'year'];
    const results = [];

    console.log('🔄 تحديث جميع الإحصائيات...');

    for (const period of periods) {
      // إحصائيات وهمية لكل فترة
      const statistics = {
        totalOrders: Math.floor(Math.random() * 200) + 50,
        activeOrders: Math.floor(Math.random() * 50) + 10,
        deliveredOrders: Math.floor(Math.random() * 100) + 30,
        inDeliveryOrders: Math.floor(Math.random() * 30) + 5,
        cancelledOrders: Math.floor(Math.random() * 10) + 1,
        totalProfits: Math.random() * 200000 + 50000,
        realizedProfits: Math.random() * 100000 + 30000,
        expectedProfits: Math.random() * 80000 + 20000,
        averageProfitPerOrder: Math.random() * 1000 + 500,
        bestProduct: 'هاتف آيفون 15 برو ماكس',
        bestProductSales: Math.floor(Math.random() * 50) + 10,
        bestProductProfit: Math.random() * 50000 + 10000,
        ordersGrowth: Math.random() * 30 - 10,
        profitsGrowth: Math.random() * 40 - 15
      };

      await saveStatisticsToDatabase(statistics, period);

      results.push({
        period: period,
        totalOrders: statistics.totalOrders,
        totalProfits: statistics.totalProfits,
        realizedProfits: statistics.realizedProfits,
        expectedProfits: statistics.expectedProfits
      });
    }

    res.json({
      success: true,
      message: 'تم تحديث جميع الإحصائيات بنجاح',
      results: results
    });

  } catch (error) {
    console.error('خطأ في تحديث الإحصائيات:', error);
    res.status(500).json({ error: 'فشل في تحديث الإحصائيات' });
  }
});

module.exports = router;
