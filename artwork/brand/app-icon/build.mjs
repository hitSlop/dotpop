import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const bundle=path.resolve(root,'../../../apps/apple/App/Shared/AppIcon.icon');
await fs.mkdir(path.join(bundle,'Assets'),{recursive:true});
const svg=b=>`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">${b}</svg>`;
const pane='<rect x="88" y="88" width="848" height="848" rx="192"';
const assets={
 '01-blended-color.svg':svg(`<defs>
 <linearGradient id="base" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#279DF4"/><stop offset=".48" stop-color="#7951F6"/><stop offset="1" stop-color="#CC36D9"/></linearGradient>
 <radialGradient id="blue" cx=".08" cy=".12" r=".92"><stop stop-color="#25D2F9" stop-opacity=".92"/><stop offset=".58" stop-color="#469CFC" stop-opacity=".4"/><stop offset="1" stop-color="#5578FF" stop-opacity="0"/></radialGradient>
 <radialGradient id="pink" cx="1" cy=".25" r=".97"><stop stop-color="#F979E5" stop-opacity=".88"/><stop offset=".56" stop-color="#D66AED" stop-opacity=".38"/><stop offset="1" stop-color="#B351F8" stop-opacity="0"/></radialGradient>
 <radialGradient id="violet" cx=".25" cy="1.05" r=".85"><stop stop-color="#6624F5" stop-opacity=".8"/><stop offset="1" stop-color="#7A4AF6" stop-opacity="0"/></radialGradient>
 </defs>${pane} fill="url(#base)"/>${pane} fill="url(#blue)"/>${pane} fill="url(#pink)"/>${pane} fill="url(#violet)"/>`),
 '02-soft-glass-current.svg':svg(`<defs><clipPath id="clip">${pane}/></clipPath><linearGradient id="flow" x1=".1" y1=".2" x2=".9" y2=".9"><stop stop-color="#B2EDFF" stop-opacity=".05"/><stop offset=".45" stop-color="#B3B7FF" stop-opacity=".44"/><stop offset=".8" stop-color="#D6AEFF" stop-opacity=".12"/><stop offset="1" stop-color="#E7BFFF" stop-opacity="0"/></linearGradient></defs><path clip-path="url(#clip)" fill="url(#flow)" d="M-100 870 C80 590 384 728 570 470 C740 234 568 54 1040 -130 L1200 200 C878 234 960 530 754 712 C530 914 260 782 116 1110Z"/>`),
 '03-raised-lens.svg':svg(`${pane} fill="#D2E5FF"/>`)
};
for(const [n,s] of Object.entries(assets)){await fs.writeFile(path.join(bundle,'Assets',n),s);}
const layer=(file,opacity=1)=>({'image-name':file,name:file.slice(3,-4).replaceAll('-',' '),glass:true,opacity,position:{scale:1,'translation-in-points':[0,0]}});
const group=(name,layers,t,b,s,d,shadow,specular=true)=>({name,layers,specular,lighting:'combined','blur-material':b,translucency:{enabled:true,value:t},refractivity:{enabled:true,strength:s,depth:d},shadow:{kind:'layer-color',opacity:shadow}});
const m={
 'color-space-for-untagged-svg-colors':'display-p3',features:['refractivity'],
 fill:{solid:'srgb:0.98,0.985,1,1'},'supported-platforms':{squares:'shared'},
 groups:[
 group('03 · Polished raised glass',[layer('03-raised-lens.svg',.10)],.94,.025,.7,.52,.08),
 group('02 · Soft flowing glass',[layer('02-soft-glass-current.svg',.52)],.72,.16,.38,.3,.025,false),
 group('01 · Blended blue violet pink',[layer('01-blended-color.svg')],.10,.055,.25,.22,.15)
 ]
};
m['fill-specializations']=[{value:m.fill},{appearance:'dark',value:{solid:'srgb:0.90,0.925,0.98,1'}},{appearance:'tinted',value:{solid:'gray:1,1'}}];
m.groups[0].layers[0]['opacity-specializations']=[{appearance:'dark',value:.06},{appearance:'tinted',value:.10}];
m.groups[1].layers[0]['fill-specializations']=[{appearance:'tinted',value:{solid:'gray:0.65,1'}}];
m.groups[2].layers[0]['fill-specializations']=[{appearance:'tinted',value:{solid:'gray:0.35,1'}}];
await fs.writeFile(path.join(bundle,'icon.json'),JSON.stringify(m,null,2)+'\n');
console.log(bundle);
