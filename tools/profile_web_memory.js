// Measure the peak memory of the browser page process while the web build
// boots, in WebKit (the Safari/iPhone engine) with an iPhone viewport.
// iPhones close a Safari tab at roughly 1-1.5 GB; 0.2.0-0.2.5 peaked near 1.9 GB.
// Usage: NODE_PATH=<dir with playwright> node tools/profile_web_memory.js [url] [screenshot.png]
// Start the local server first: python3 tools/serve_web.py
const {webkit,devices}=require('playwright');
const {execSync}=require('child_process');
const LIMIT_MB=1000; // Review threshold, well under the observed phone crash range.
function pageProcessMb(){
 const lines=execSync('ps -axo rss,command').toString().split('\n').filter(l=>/WebKit\.WebContent/.test(l));
 return Math.max(0,...lines.map(l=>Number(l.trim().split(/\s+/)[0])/1024|0));
}
(async()=>{
 const url=process.argv[2]||'http://127.0.0.1:8877/',shot=process.argv[3];
 const browser=await webkit.launch({headless:true});
 const page=await(await browser.newContext({...devices['iPhone 13']})).newPage();
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 page.goto(url);
 let peak=0,opened=false,started=Date.now();
 while(Date.now()-started<60000){
  await new Promise(r=>setTimeout(r,40));
  peak=Math.max(peak,pageProcessMb());
  if(!opened){
   opened=await page.evaluate(()=>!document.querySelector('#loading')||!document.querySelector('#ready').hidden).catch(()=>false);
   if(opened)await page.click('#play').catch(()=>{});
  }
  else if(Date.now()-started>8000)break;
 }
 if(shot)await page.screenshot({path:shot});
 await browser.close();
 const result={url,engine:'WebKit',viewport:'iPhone 13',opened,peak_page_mb:peak,limit_mb:LIMIT_MB,errors,result:opened&&peak<=LIMIT_MB&&!errors.length?'PASS':'FAIL'};
 console.log(JSON.stringify(result));
 process.exit(result.result==='PASS'?0:1);
})();
