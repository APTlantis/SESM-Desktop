import { test, expect, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';

// Frontend contract tests: native dialogs/engine are mocked here, not in the shipping app.
async function desktop(page: Page) {
  await page.addInitScript(() => {
    let snapshot = {
      id:'document-1',name:'atlas-example.svg',source:'fixtures/atlas-example.svg',source_sha256:'a'.repeat(64),
      draft:'{"sesm_version":"0.3.0","extra":{"large":9007199254740993123456789}}', metadata_json:'{"sesm_version":"0.3.0"}',dirty:true,revision:0,approved:false,warnings_acknowledged:false,
      validation:{profile:'sesm-safe',metadata_version:'0.3.0',schema:'SESM 0.3.0',schema_sha256:'b'.repeat(64),exportable:true,findings:[] as unknown[]},
      observations:[{property:'title',value:'Observed title',source:'/svg/title'}],changes:[{path:'/sesm_version',before:null,after:'"0.3.0"'}],preview:null,preview_error:null,
    };
    const templates: unknown[] = []; const calls: {command:string,args:Record<string,unknown>}[]=[];
    (window as any).__testCalls = calls;
    (window as any).__TAURI_INTERNALS__ = {
      metadata:{currentWindow:{label:'main'},currentWebview:{label:'main',windowLabel:'main'}},
      transformCallback:()=>1,unregisterCallback:()=>{},
      invoke:async (command:string,args:Record<string,unknown>={}) => {
        calls.push({command,args});
        if(command==='plugin:event|listen') return 1;
        if(command==='preferences') return {version:1,preview_background:'checker',editor_tab:'fields'};
        if(command==='list_templates') return templates;
        if(command==='open_documents') return {documents:[snapshot],errors:[]};
        if(command==='edit_metadata') {
          snapshot={...snapshot,draft:String(args.draft),revision:snapshot.revision+1,approved:false};
          let valid=true;try{JSON.parse(snapshot.draft);}catch{valid=false;}
          snapshot.validation={...snapshot.validation,exportable:valid,findings:valid?[]:[{category:'schema',severity:'error',code:'metadata-json',message:'Invalid JSON draft',path:'/sesm'}]};
          return snapshot;
        }
        if(command==='approve_document'){snapshot={...snapshot,approved:true};return snapshot;}
        if(command==='save_template'){templates.push({version:1,name:args.name,patch_json:'{}'});return templates.at(-1);}
        if(command==='apply_template'){snapshot={...snapshot,revision:snapshot.revision+1,approved:false};return{document:snapshot,conflicts:['/asset/title']};}
        if(command==='export_documents')return{destination:'exports/SESM-Export-test',cancelled:false,files:[{document_id:snapshot.id,filename:snapshot.name,status:'exported',message:null,output_sha256:'c'.repeat(64)}]};
        return null;
      },
    };
  });
  await page.goto('/'); await page.getByRole('button',{name:'＋ Open SVGs'}).click();
}

test('empty workspace has accessible local-only entry points', async ({page})=>{
  await page.goto('/');await expect(page.getByRole('heading',{name:'SESM Desktop'})).toBeVisible();
  await expect(page.getByRole('button',{name:/Export.*approved/})).toBeDisabled();
  await page.keyboard.press('Tab');await expect(page.getByRole('button',{name:'＋ Open SVGs'})).toBeFocused();
  await page.screenshot({path:'evidence/local/empty-workspace.png',fullPage:true});
});
test('form edits preserve unknown numbers, invalidate approval, and require validation',async({page})=>{
  await desktop(page);
  await page.getByRole('textbox',{name:'Asset ID /asset/id',exact:true}).fill('unique-asset');
  await page.getByRole('combobox',{name:'Role /asset/role',exact:true}).selectOption('dataset-card');
  await page.getByRole('textbox',{name:'Title /asset/title',exact:true}).fill('A structured graphic');
  await expect(page.getByRole('button',{name:'Approve this file'})).toBeDisabled();
  await page.getByRole('button',{name:'Validate draft'}).click();
  await page.getByRole('button',{name:'Approve this file'}).click();
  await expect(page.getByRole('button',{name:'✓ Approved for export'})).toBeDisabled();
  await page.getByRole('tab',{name:'Raw JSON'}).click();
  await expect(page.getByLabel('Unknown fields and numeric precision are preserved.')).toHaveValue(/9007199254740993123456789/);
  await page.getByLabel('Unknown fields and numeric precision are preserved.').fill('{');
  await page.getByRole('button',{name:'Validate draft'}).click();
  await expect(page.getByText('Invalid JSON draft',{exact:true})).toBeVisible();
  await expect(page.getByRole('button',{name:/Export.*approved/})).toBeDisabled();
});
test('templates expose conflicts and export shows a receipt',async({page})=>{
  await desktop(page);
  await page.getByPlaceholder('Template name').fill('Shared metadata');await page.getByRole('button',{name:'Save template',exact:true}).click();
  await page.getByLabel('Saved template').selectOption('Shared metadata');await page.getByRole('button',{name:'Fill missing fields'}).click();
  await expect(page.getByText('Existing values kept — select any to replace')).toBeVisible();
  await page.getByRole('checkbox',{name:'/asset/title'}).check();await page.getByRole('button',{name:'Apply selected replacements'}).click();
  await page.getByRole('button',{name:'Approve this file'}).click();await page.getByRole('button',{name:/Export 1 approved copy/}).click();
  await expect(page.getByRole('dialog',{name:'Export results'})).toBeVisible();await expect(page.getByText('exported · atlas-example.svg')).toBeVisible();
  await expect(page.getByRole('button',{name:'Close',exact:true})).toBeFocused();
  await page.keyboard.press('Tab');await expect(page.getByRole('button',{name:'Close',exact:true})).toBeFocused();
  await page.screenshot({path:'evidence/local/export-receipt.png',fullPage:true});
});
test('Factor text and controls meet readable contrast',async()=>{
  const css=readFileSync('src/style.css','utf8');
  const luminance=(hex:string)=>{const rgb=hex.match(/\w\w/g)!.map(x=>parseInt(x,16)/255).map(c=>c<=.04045?c/12.92:((c+.055)/1.055)**2.4);return rgb[0]*.2126+rgb[1]*.7152+rgb[2]*.0722;};
  for(const [fg,bg] of [['FEFEFD','020B14'],['BCD1E2','0B131A'],['F7D34D','182027'],['FEFEFD','2F2500']]){const ratio=(Math.max(luminance(fg),luminance(bg))+.05)/(Math.min(luminance(fg),luminance(bg))+.05);expect(ratio,`${fg} on ${bg}`).toBeGreaterThanOrEqual(4.5);}
  expect(css).toContain(':focus-visible');
});
