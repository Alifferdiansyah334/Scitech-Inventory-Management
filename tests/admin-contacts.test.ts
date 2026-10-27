import {it,expect} from 'vitest';
import {adminContacts} from '@/lib/backend/admin-contacts';
it('exposes exactly the two support destinations selected by the owner',()=>{
  expect(adminContacts.map(c=>c.phone)).toEqual(['6288212854299','6288289375343']);
  expect(new Set(adminContacts.map(c=>c.id)).size).toBe(2);
});
