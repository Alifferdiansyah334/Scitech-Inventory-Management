import {beforeEach,describe,expect,it,vi} from 'vitest';
const mocks=vi.hoisted(()=>({createUser:vi.fn(),upsert:vi.fn(),single:vi.fn(),requestOtp:vi.fn(),rateLimit:vi.fn()}));
vi.mock('server-only',()=>({}));
vi.mock('next/navigation',()=>({redirect:vi.fn()}));
vi.mock('@/lib/supabase/server',()=>({createClient:vi.fn()}));
vi.mock('@/lib/supabase/db',()=>({database:vi.fn()}));
vi.mock('@/lib/auth/session',()=>({currentProfile:vi.fn(),requireProfile:vi.fn(),requireAdmin:vi.fn()}));
vi.mock('@/lib/auth/rate-limit',()=>({enforceRateLimit:mocks.rateLimit}));
vi.mock('@/lib/auth/otp',()=>({requestOtp:mocks.requestOtp,checkOtp:vi.fn(),sessionForOtpUser:vi.fn()}));
vi.mock('@/lib/supabase/admin',()=>({createAdminClient:()=>({auth:{admin:{createUser:mocks.createUser}},from:()=>({upsert:mocks.upsert})})}));
import {registerUser} from '@/lib/actions/users';
beforeEach(()=>{
  vi.resetAllMocks();
  mocks.createUser.mockResolvedValue({data:{user:{id:'new-user',email:'user@example.com'}},error:null});
  mocks.upsert.mockReturnValue({select:()=>({single:mocks.single})});
  mocks.single.mockResolvedValue({data:{user_id:'new-user',email:'user@example.com',role:'client'},error:null});
});
describe('Apps registration API',()=>{
  it('creates an unverified borrower and requests the registration OTP',async()=>{
    const result=await registerUser({full_name:'Pengguna Uji',email:'user@example.com',password:'ValidPass123!',role:'admin',phone:'081234567890'});
    expect(result.success).toBe(true);
    expect(mocks.createUser).toHaveBeenCalledWith(expect.objectContaining({email_confirm:false}));
    expect(mocks.upsert).toHaveBeenCalledWith(expect.objectContaining({role:'client',is_active:true,phone:'081234567890'}),expect.anything());
    expect(mocks.requestOtp).toHaveBeenCalledWith('user@example.com','register');
  });
  it('rejects a weak password before creating an identity or sending email',async()=>{
    const result=await registerUser({full_name:'Pengguna Uji',email:'user@example.com',password:'weakpass'});
    expect(result.success).toBe(false);
    expect(result.error).toContain('huruf besar');
    expect(mocks.createUser).not.toHaveBeenCalled();
    expect(mocks.requestOtp).not.toHaveBeenCalled();
  });
  it('does not report success when the email provider fails',async()=>{
    mocks.requestOtp.mockRejectedValue(new Error('Email belum dapat dikirim. Silakan coba kembali nanti.'));
    const result=await registerUser({full_name:'Pengguna Uji',email:'user@example.com',password:'ValidPass123!'});
    expect(result.success).toBe(false);
    expect(result.error).toContain('Akun sudah dibuat');
    expect(result.error).toContain('login OTP');
  });
});
