export const config = {
  runtime: 'edge',
};

export default async function handler(request) {
  const { searchParams } = new URL(request.url);
  const newsId = searchParams.get('id') || '';
  const titleParam = searchParams.get('t');
  
  let title = titleParam ? decodeURIComponent(titleParam) : '4TK News';
  let image = '';

  const html = `<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    
    <!-- Open Graph meta tags for link preview -->
    <meta property="og:site_name" content="4TK News">
    <meta property="og:type" content="article">
    <meta property="og:title" content="${title}">
    <meta property="og:description" content="Đọc trên 4TK News">
    ${image ? `<meta property="og:image" content="${image}">` : ''}
    ${image ? '<meta property="og:image:width" content="1200">' : ''}
    ${image ? '<meta property="og:image:height" content="630">' : ''}
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${title}">
    <meta name="twitter:description" content="Đọc trên 4TK News">
    ${image ? `<meta name="twitter:image" content="${image}">` : ''}
    
    <title>${title} - 4TK News</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 400px;
            text-align: center;
        }
        .spinner {
            width: 60px;
            height: 60px;
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 30px;
        }
        @keyframes spin {
            100% { transform: rotate(360deg); }
        }
        h1 {
            font-size: 28px;
            margin-bottom: 15px;
        }
        .status {
            font-size: 16px;
            opacity: 0.9;
            margin-bottom: 30px;
        }
        .card {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 25px;
            margin-top: 30px;
        }
        .card h3 {
            font-size: 18px;
            margin-bottom: 15px;
        }
        .steps {
            text-align: left;
            line-height: 1.8;
        }
        .steps li {
            margin-bottom: 8px;
        }
        .btn {
            display: inline-block;
            margin-top: 20px;
            padding: 15px 30px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 30px;
            font-weight: 600;
            font-size: 16px;
            transition: transform 0.2s;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
        }
        .icon {
            font-size: 48px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">📰</div>
        <div class="spinner"></div>
        <h1>Đang mở 4TK News...</h1>
        <p class="status" id="status">Đang chuyển hướng...</p>
        
        <a href="newsai://open/${newsId}" class="btn" id="openBtn">Mở trong App</a>
        
        <div class="card">
            <h3>⚠️ App không tự động mở?</h3>
            <ol class="steps">
                <li>Nhấn nút "Mở trong App" bên trên</li>
                <li>Chọn "4TK News" trong popup</li>
                <li>Hoặc download app nếu chưa cài</li>
            </ol>
        </div>
    </div>

    <script>
        const deepLink = 'newsai://open/${newsId}';
        
        // Auto redirect to app
        window.location.href = deepLink;
        
        // After 2.5s show message
        setTimeout(() => {
            document.getElementById('status').innerHTML = 
                '⚠️ Chưa mở được app?<br>Nhấn nút bên dưới hoặc tải app';
        }, 2500);
    </script>
</body>
</html>`;

  return new Response(html, {
    headers: {
      'content-type': 'text/html;charset=UTF-8',
      'cache-control': 'public, max-age=0, must-revalidate',
    },
  });
}
