const express = require('express');
const router = express.Router();

// 📊 جلب الإحصائيات الحقيقية المحفوظة
router.get('/real-statistics', async (req, res) => {
  try {
    const { period = 'month' } = req.query;
    
    console.log(`🔄 جلب الإحصائيات للفترة: ${period}`);
    
    // إحصائيات وهمية للاختبار
    const statistics = {
      totalOrders: 150,
      activeOrders: 45,
      deliveredOrders: 85,
      inDeliveryOrders: 15,
      cancelledOrders: 5,
      totalProfits: 125000.50,
      realizedProfits: 75000.25,
      expectedProfits: 50000.25,
      averageProfitPerOrder: 833.34,
      bestProduct: 'هاتف آيفون 15 برو ماكس',
      bestProductSales: 34,
      bestProductProfit: 26250.75,
      ordersGrowth: 12.5,
      profitsGrowth: 18.3
    };
    
    console.log('✅ تم إنشاء الإحصائيات الوهمية بنجاح');
    
    res.json({
      success: true,
      period: period,
      statistics: statistics,
      totalOrders: statistics.totalOrders,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('خطأ في جلب الإحصائيات:', error);
    res.status(500).json({ error: 'فشل في جلب الإحصائيات' });
  }
});

// 📊 اختبار الإحصائيات
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'اختبار الإحصائيات يعمل بنجاح!',
    statistics: {
      totalOrders: 150,
      activeOrders: 45,
      deliveredOrders: 85,
      inDeliveryOrders: 15,
      cancelledOrders: 5,
      totalProfits: 125000.50,
      realizedProfits: 75000.25,
      expectedProfits: 50000.25,
      averageProfitPerOrder: 833.34,
      bestProduct: 'هاتف آيفون 15 برو ماكس',
      bestProductSales: 34,
      bestProductProfit: 26250.75,
      ordersGrowth: 12.5,
      profitsGrowth: 18.3
    },
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
