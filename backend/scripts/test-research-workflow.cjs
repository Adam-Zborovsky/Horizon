const fs=require('fs');
const assert=require('node:assert/strict');
const path=require('path');
const root=__dirname;
const AsyncFunction=Object.getPrototypeOf(async function(){}).constructor;
const workflow=JSON.parse(fs.readFileSync(path.join(root,'../../n8n-workflow.json')));
const run=async(name,j,http)=>{const n=workflow.nodes.find(n=>n.name===name);const f=new AsyncFunction('$input',n.parameters.jsCode);return (await f.call({helpers:{httpRequest:http}},{first:()=>({json:j})}))[0].json;};
const http=async o=>{const r=await fetch(o.url,{headers:o.headers,signal:AbortSignal.timeout(o.timeout||20000)});if(!r.ok)throw new Error('HTTP '+r.status);return o.json?r.json():r.text();};
(async()=>{
  for(const n of workflow.nodes) if(n.parameters.jsCode) new AsyncFunction('$input','$env',n.parameters.jsCode);
  console.log('PASS: all workflow Code nodes compile as n8n async bodies');
  const quotes=[];
  for(const ticker of ['AMD','ALAB']) {const d=await http({url:'https://query1.finance.yahoo.com/v8/finance/chart/'+ticker+'?interval=1d&range=1d',headers:{'User-Agent':'Mozilla/5.0'},json:true});const r=d.chart.result[0],m=r.meta;quotes.push({ticker,name:m.longName||m.shortName||ticker,price:m.regularMarketPrice,change:(m.regularMarketPrice/m.chartPreviousClose-1)*100});}
  let j={userId:'6a9bfda981baabd5b4d829db',tickers:['AMD','ALAB'],topics:[],watchlist_quotes:quotes,pool_quotes:[],news_feeds:[],news_takeaways:{}};
  j=await run('Fetch Holding History',j,http);
  for(const q of j.watchlist_quotes){assert(q.research.session_count>200);assert(q.history.length>1);assert(q.research.returns.month!==null);console.log(q.ticker,JSON.stringify({date:q.research.as_of,sessions:q.research.session_count,history:q.history.length,returns:q.research.returns}));}
  j=await run('Fetch Holding News',j,http);
  j=await run('Build Market Agent Prompt',j,http);
  assert(j.market_agent_system.includes('ALREADY HOLDS'));
  assert(JSON.parse(j.market_agent_user).holdings.length===2);
  const fixture=ticker=>({ticker,sentiment_score:0,market_outlook:'Test fixture: no live investment conclusion.',catalysts:[],risks:[],potential_price_action:'Test fixture for parser compatibility only.',evidence_ids:[]});
  const valid={...j,market_raw:JSON.stringify({analyses:j.tickers.map(fixture)})};
  const parsed=await run('Extract Market Output',valid,http);
  const result=await run('Assemble Payload',parsed,http);
  assert.equal(result.data.market_analysis.length,2);
  for(const q of result.data.market_analysis)assert(q.history.length>1);
  for(const analyses of [[fixture('AMD')],[fixture('AMD'),fixture('AMD')],[{...fixture('AMD'),evidence_ids:['invented']},fixture('ALAB')]]) await assert.rejects(run('Extract Market Output',{...j,market_raw:JSON.stringify({analyses})},http));
  const missing=await run('Fetch Holding History',{...j,watchlist_quotes:[]},async()=>{throw new Error('Simulated unavailable provider');});
  assert.equal(missing.watchlist_quotes.length,2);assert(missing.watchlist_quotes.every(q=>q.research.error&&q.history.length===0));
  console.log('PASS: real history/news input, holding context, payload compatibility, full coverage, duplicate/evidence rejection, missing-data behavior');
})().catch(e=>{console.error(e);process.exit(1);});
