// مسارات رفع الصور - Upload Routes
const express = require('express');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

const router = express.Router();

// إعداد Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// إعداد Multer للذاكرة
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('يجب أن يكون الملف صورة'), false);
    }
  },
});

// دالة لرفع الصورة إلى Cloudinary
const uploadToCloudinary = (buffer, folder = 'montajati') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: folder,
        resource_type: 'image',
        transformation: [
          { width: 800, height: 600, crop: 'limit' },
          { quality: 'auto' },
          { format: 'auto' },
        ],
      },
      (error, result) => {
        if (error) {
          reject(error);
        } else {
          resolve(result);
        }
      }
    );
    
    streamifier.createReadStream(buffer).pipe(uploadStream);
  });
};

// رفع صورة واحدة
router.post('/single', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'لم يتم اختيار صورة',
      });
    }
    
    // رفع الصورة إلى Cloudinary
    const result = await uploadToCloudinary(req.file.buffer);
    
    res.status(200).json({
      success: true,
      message: 'تم رفع الصورة بنجاح',
      data: {
        url: result.secure_url,
        public_id: result.public_id,
        width: result.width,
        height: result.height,
        format: result.format,
        size: result.bytes,
      },
    });
  } catch (error) {
    console.error('خطأ في رفع الصورة:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في رفع الصورة',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

// رفع عدة صور
router.post('/multiple', upload.array('images', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'لم يتم اختيار صور',
      });
    }
    
    // رفع جميع الصور
    const uploadPromises = req.files.map(file => 
      uploadToCloudinary(file.buffer)
    );
    
    const results = await Promise.all(uploadPromises);
    
    const images = results.map(result => ({
      url: result.secure_url,
      public_id: result.public_id,
      width: result.width,
      height: result.height,
      format: result.format,
      size: result.bytes,
    }));
    
    res.status(200).json({
      success: true,
      message: 'تم رفع الصور بنجاح',
      data: {
        images,
        count: images.length,
      },
    });
  } catch (error) {
    console.error('خطأ في رفع الصور:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في رفع الصور',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
});

// حذف صورة من Cloudinary
router.delete('/:public_id', async (req, res) => {
  try {
    const { public_id } = req.params;
    
    // حذف الصورة من Cloudinary
    const result = await cloudinary.uploader.destroy(public_id);
    
    if (result.result === 'ok') {
      res.status(200).json({
        success: true,
        message: 'تم حذف الصورة بنجاح',
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'الصورة غير موجودة',
      });
    }
  } catch (error) {
    console.error('خطأ في حذف الصورة:', error);
    res.status(500).json({
      success: false,
      message: 'خطأ في حذف الصورة',
    });
  }
});

module.exports = router;
