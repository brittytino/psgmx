import { redirect } from 'next/navigation'

// /app is a guarded route — middleware will redirect to /login if not authenticated.
// If the user IS authenticated, middleware lets them through and we redirect to /student.
export default function AppEntrypoint() {
  redirect('/student')
}
