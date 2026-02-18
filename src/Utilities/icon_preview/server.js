const http = require('http');
const fs = require('fs');
const path = require('path');

const root = process.cwd();
const mime = {
  '.html':'text/html', '.json':'application/json', '.png':'image/png', '.jpg':'image/jpeg', '.svg':'image/svg+xml', '.css':'text/css', '.js':'application/javascript'
};

const server = http.createServer((req,res)=>{
  try{
    let urlPath = decodeURIComponent(req.url.split('?')[0]);
    if(urlPath === '/') urlPath = '/icon_preview.html';
    const filePath = path.join(root, urlPath);
    if(!filePath.startsWith(root)) { res.statusCode = 403; res.end('Forbidden'); return; }
    fs.stat(filePath, (err, stat)=>{
      if(err){ res.statusCode = 404; res.end('Not found'); return; }
      const ext = path.extname(filePath).toLowerCase();
      res.setHeader('Content-Type', mime[ext] || 'application/octet-stream');
      fs.createReadStream(filePath).pipe(res);
    });
  }catch(e){ res.statusCode = 500; res.end('Server error'); }
});

const port = process.env.PORT || 8000;
server.listen(port, ()=> console.log(`HTTP server listening on http://localhost:${port}`));
