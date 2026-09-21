import { redirect } from 'next/navigation';

// /hod route is no longer used — HOD users are treated as faculty.
// Redirect anyone who lands here to the faculty dashboard.
export default function HodRedirect() {
  redirect('/faculty');
}
