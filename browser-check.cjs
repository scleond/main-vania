// Throwaway acceptance probe. Uses existing local Playwright; no project dependency installation.
const {chromium,firefox}=require('/Users/cleon/projects/cbs-fantasy-digest/node_modules/playwright');
const fs=require('node:fs');
const path=require('node:path');
const root=__dirname;
const name=process.argv[2]||'chromium';
const browserType=name==='firefox'?firefox:chromium;
const profile=path.join('/private/tmp','main-vania-probe-'+name);
const url='http://127.0.0.1:8766/';
const result={browser:name,source:'local browser automation; not retail Safari',checks:{},errors:[]};
let context;
function check(name,ok,detail){result.checks[name]={pass:!!ok,detail};if(!ok)throw Error(name+': '+JSON.stringify(detail));}
async function launch(){return browserType.launchPersistentContext(profile,{headless:true,viewport:{width:1280,height:720}});}
async function ready(page){await page.waitForFunction(()=>window.__vania_probe?.ready,{},{timeout:60000});return page.evaluate(()=>window.__vania_probe);}
async function press(page,key){await page.keyboard.press(key);await page.waitForTimeout(300);return page.evaluate(()=>window.__vania_probe);}
(async()=>{
 try{
 context=await launch();let page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 const start=Date.now();await page.goto(url);let s=await ready(page);result.startupMs=Date.now()-start;
 result.ua=await page.evaluate(()=>navigator.userAgent);result.engine=s.engine;
 await page.locator('#canvas').focus();s=await press(page,'n');check('new run',s.playing&&s.state.souls===0,s);
 const x=s.x;await page.keyboard.down('d');await page.waitForTimeout(300);await page.keyboard.up('d');await page.waitForTimeout(250);s=await page.evaluate(()=>window.__vania_probe);check('movement',s.x>x+20,{from:x,to:s.x});
 const y=s.y;await page.keyboard.press('Space');await page.waitForFunction(y=>window.__vania_probe.y<y-5,y,{timeout:2000});s=await page.evaluate(()=>window.__vania_probe);check('jump',s.y<y-5,{from:y,to:s.y});await page.waitForTimeout(750);
 s=await press(page,'u');check('visible upgrade and souls',s.upgraded&&s.state.souls===3&&s.state.upgrades.length===1,s.state);
 s=await press(page,'h');check('shrine fixture',s.state.shrines.includes('Ember'),s.state);
 await page.waitForTimeout(500);s=await press(page,'r');const checkpoint=s.state.checkpoint;
 await page.keyboard.down('d');await page.waitForTimeout(350);await page.keyboard.up('d');s=await press(page,'k');check('respawn',Math.abs(s.x-checkpoint[0])<3,{checkpoint,x:s.x});
 const dashStart=s.x;s=await press(page,'Shift');check('dash',s.x>dashStart+20,{from:dashStart,to:s.x});
 check('save written',s.persistent&&s.save_ok,s);
 await page.waitForTimeout(1500);await page.reload();await ready(page);await page.locator('#canvas').focus();s=await press(page,'c');check('reload preserves fixture',s.state.souls===3&&s.state.upgrades.length===1&&s.state.shrines.includes('Ember')&&s.state.modifiers['enemy-1']==='Wind',s.state);
 const timing=await page.evaluate(()=>new Promise(resolve=>{const samples=[];let last=performance.now();function frame(now){samples.push(now-last);last=now;if(samples.length<120)requestAnimationFrame(frame);else{samples.sort((a,b)=>a-b);resolve({median:samples[60],p95:samples[114],samples:120});}}requestAnimationFrame(frame);}));result.frameTimingMs=timing;
 await page.screenshot({path:path.join(root,name+'.png')});
 await context.close();context=await launch();page=await context.newPage();await page.goto(url);await ready(page);await page.locator('#canvas').focus();s=await press(page,'c');check('browser restart persists fixture',s.state.souls===3&&s.state.shrines.includes('Ember')&&s.state.modifiers['enemy-1']==='Wind',s.state);
 await page.goto(url+'?storage=off');await ready(page);await page.locator('#canvas').focus();await press(page,'n');s=await press(page,'u');check('simulated session-only play',!s.persistent&&s.playing&&s.state.souls===3,s);
 await page.reload();s=await ready(page);check('simulated session-only reload resets',!s.persistent&&s.state.souls===0,s.state);
 result.status='passed';
 }catch(e){result.status='failed';result.failure=String(e);}
 finally{if(context)await context.close();fs.writeFileSync(path.join(root,name+'-results.json'),JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,2));process.exitCode=result.status==='passed'?0:1;}
})();
