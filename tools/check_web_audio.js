// Usage: NODE_PATH=<dir with playwright> node tools/check_web_audio.js <url> [webkit]
// Prints the loudest output level on the menu and after Start; 0.0000 means silence.
// Measures what actually reaches the speakers: every node connected to the
// destination is also tapped into an analyser; we sample its loudness.
const {chromium,webkit}=require('playwright');
(async()=>{
 const engines=process.argv[3]==='webkit'?[webkit]:[chromium];
 for(const engine of engines){
  const browser=await engine.launch({headless:true});
  const page=await(await browser.newContext({viewport:{width:844,height:390}})).newPage();
  const logs=[];page.on('console',m=>logs.push(m.text()));page.on('pageerror',e=>logs.push('PAGEERROR '+e.message));
  await page.addInitScript(()=>{
   window.__levels=[];
   const orig=AudioNode.prototype.connect;
   AudioNode.prototype.connect=function(target,...rest){
    const r=orig.call(this,target,...rest);
    try{ if(target instanceof AudioDestinationNode){ const ctx=this.context;
      if(!ctx.__an){ctx.__an=ctx.createAnalyser();ctx.__an.fftSize=2048;}
      orig.call(this,ctx.__an); window.__ctxs=(window.__ctxs||new Set()).add(ctx);} }catch(e){}
    return r;};
   setInterval(()=>{for(const ctx of (window.__ctxs||[])){const a=new Float32Array(2048);ctx.__an.getFloatTimeDomainData(a);let s=0;for(const v of a)s+=v*v;window.__levels.push(Math.sqrt(s/a.length));}},200);
  });
  await page.goto(process.argv[2]);
  await page.waitForSelector('#ready:not([hidden])',{timeout:120000});
  await page.click('#play');
  await page.waitForTimeout(6000);
  const mark=await page.evaluate(()=>window.__levels.length);
  await page.mouse.click(250,150); // Start
  await page.waitForTimeout(5000);
  const res=await page.evaluate((m)=>{const L=window.__levels;const mx=a=>a.length?Math.max(...a):0;return {menu:mx(L.slice(0,m)).toFixed(4),after:mx(L.slice(m)).toFixed(4),n:L.length}},mark);
  console.log(engine.name(),JSON.stringify(res));
  console.log(logs.filter(l=>/audio|Audio|PAGEERROR|sample|bus/i.test(l)).slice(0,10).join('\n'));
  await browser.close();
 }
})();
