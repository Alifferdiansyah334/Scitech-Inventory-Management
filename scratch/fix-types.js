const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach((file) => {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.tsx') || file.endsWith('.ts')) {
        results.push(file);
      }
    }
  });
  return results;
}

const files = [
  ...walk('d:/Scitech-Inventory-Management/app'),
  ...walk('d:/Scitech-Inventory-Management/components'),
  ...walk('d:/Scitech-Inventory-Management/lib')
];

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  let original = content;

  // Replace user.profile with user (where user is actually the profile object now)
  // Wait, in page.tsx, they might have `const user = await getCurrentUserProfile();` and then use `user.profile.full_name`.
  content = content.replace(/user\.profile\.userId/g, 'user.user_id');
  content = content.replace(/user\.profile\.user_id/g, 'user.user_id');
  content = content.replace(/user\.profile\./g, 'user.');
  content = content.replace(/profile\.profile\./g, 'profile.');
  
  // Replace $id with id
  content = content.replace(/\$id/g, 'id');
  
  // Replace userId with user_id
  content = content.replace(/\.userId/g, '.user_id');

  // Fix implicit any in active-loans-list.tsx
  if (file.includes('active-loans-list.tsx')) {
    content = content.replace(/loans\.map\(\(loan\)/g, 'loans.map((loan: Loan)');
  }
  
  // Fix implicit any in my-loans-table.tsx
  if (file.includes('my-loans-table.tsx')) {
    content = content.replace(/paginatedData\.map\(\(loan, idx\)/g, 'paginatedData.map((loan: Loan, idx: number)');
  }

  // Fix inventory-table.tsx Header Element issue
  if (file.includes('inventory-table.tsx')) {
    content = content.replace(/header: \(\) => <div className="text-right">Actions<\/div>,/g, 'header: "Actions",');
  }

  // Fix loan-detail-dialog.tsx buildPreviewUrl args
  if (file.includes('loan-detail-dialog.tsx')) {
    content = content.replace(/buildPreviewUrl\(loan\.return_image_id\)/g, 'buildPreviewUrl("return-images", loan.return_image_id)');
    content = content.replace(/buildPreviewUrl\(loan\.admin_note\)/g, 'buildPreviewUrl("return-images", loan.admin_note)');
    content = content.replace(/import { appConfig, buildPreviewUrl } from/g, 'import { buildPreviewUrl } from');
  }

  // Fix gsap
  if (file.includes('gsap.ts')) {
    content = content.replace(/export \* from 'gsap';/g, ''); // just remove it to avoid conflicts, we exported { gsap }
  }

  if (content !== original) {
    fs.writeFileSync(file, content, 'utf8');
    console.log(`Updated ${file}`);
  }
}
