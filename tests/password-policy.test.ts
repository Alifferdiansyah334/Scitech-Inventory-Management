import {describe,it,expect} from 'vitest';
import {registerSchema,resetPasswordSchema} from '@/lib/validators/auth';
import {strongPasswordSchema} from '@/lib/validators/password';

describe('Password policy enforced by the apps API',()=>{
  it.each(['Aa1!aaa','lowercase1!','UPPERCASE1!','NoNumbers!','NoSymbol123','Aa1 aaaa'])('rejects a password missing a required rule',password=>{
    expect(strongPasswordSchema.safeParse(password).success).toBe(false);
    expect(registerSchema.safeParse({email:'user@example.com',full_name:'Pengguna Uji',password}).success).toBe(false);
    expect(resetPasswordSchema.safeParse({email:'user@example.com',otp:'123456',newPassword:password,confirmPassword:password}).success).toBe(false);
  });
  it('accepts the minimum compliant password and preserves symbols',()=>{
    expect(strongPasswordSchema.parse('Aa1!aaaa')).toBe('Aa1!aaaa');
    expect(strongPasswordSchema.parse('BetterPassword123!')).toBe('BetterPassword123!');
    expect(strongPasswordSchema.safeParse('Aa1!'+ 'x'.repeat(125)).success).toBe(false);
  });
});
