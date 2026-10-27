import {describe,it,expect} from 'vitest';
import {teamActivity} from '@/lib/backend/team-activity';
import type {Loan} from '@/types';
describe('Borrower team activity',()=>{
  const loan={id:'loan',item_id:'item',borrower_id:'friend',quantity:2,purpose:'private purpose',borrow_date:'2026-10-27',return_date:'2026-11-03',status:'borrowed',admin_note:'private note',admin_image_id:'private photo',borrower:{user_id:'friend',full_name:'Rekan Uji',email:'private@example.com',phone:'private phone',role:'client',created_at:'',department:'Operasional'},item:{id:'item',name:'Kamera',category:'Elektronik',quantity_total:3,quantity_available:1,is_available:true,created_at:''}} as Loan;
  it('shows an active colleague loan with only the details needed to plan inventory use',()=>{
    const result=teamActivity([loan],'viewer');
    expect(result).toEqual([expect.objectContaining({borrower_name:'Rekan Uji',item_name:'Kamera',quantity:2,is_mine:false})]);
    const data=JSON.stringify(result);
    for(const privateValue of ['private purpose','private note','private photo','private@example.com','private phone'])expect(data).not.toContain(privateValue);
  });
  it('excludes pending and closed requests and identifies the viewer’s own loan',()=>{
    expect(teamActivity(['pending','returned','cancelled','rejected'].map(status=>({...loan,status} as Loan)),'friend')).toEqual([]);
    expect(teamActivity([loan],'friend')[0].is_mine).toBe(true);
  });
});
