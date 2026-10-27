import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/auth/session";
import { updateUserRole, setUserActive } from "@/lib/actions/users";
import { apiError } from "@/lib/backend/http";
export async function PATCH(request:Request,{params}:{params:Promise<{id:string}>}){
  try { await requireAdmin(); const {id}=await params;const v=await request.json();
    const result=v.role!==undefined?await updateUserRole({userId:id,role:v.role}):await setUserActive({userId:id,isActive:v.is_active});
    return NextResponse.json(result,{status:result.success?200:400});
  }catch(error){return apiError(error);}
}
