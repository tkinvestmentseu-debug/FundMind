import * as SQLite from "expo-sqlite";
import { MIGRATIONS } from "./migrations";
const db = SQLite.openDatabase("fundmind.db");
function exec(sql:string):Promise<void>{
  return new Promise((resolve,reject)=>{ db.transaction(tx=>tx.executeSql(sql,[],()=>resolve(),(_,e)=>{reject(e);return false;})); });
}
async function ensure(){ await exec("CREATE TABLE IF NOT EXISTS __migrations (id INTEGER PRIMARY KEY)"); }
async function applied():Promise<number[]>{ return new Promise(r=>{ db.readTransaction(tx=>{ tx.executeSql("SELECT id FROM __migrations",[],(_,res)=>{ const ids:number[]=[]; for(let i=0;i<res.rows.length;i++) ids.push(res.rows.item(i).id); r(ids); }); }); }); }
async function mark(id:number){ await exec(`INSERT OR IGNORE INTO __migrations (id) VALUES (${id})`); }
export async function runMigrations(){ await ensure(); const done=new Set(await applied()); for(let i=0;i<MIGRATIONS.length;i++){ const id=i+1; if(!done.has(id)){ await exec(MIGRATIONS[i]); await mark(id); } } }
export { db };