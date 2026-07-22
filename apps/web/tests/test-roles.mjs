import dotenv from "dotenv";
dotenv.config({ path: ".env" });
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false } }
);

async function test() {
  const { data, error } = await supabase.from('users').select('reg_no, roles_label, email').in('role_label', ['Faculty', 'HOD', 'Alumni', 'Coordinator']);
  console.log('Other roles:', data, error);
}

test();
