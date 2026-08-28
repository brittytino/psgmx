import { Megaphone } from 'lucide-react'
import { LiveAnnouncements } from '@/components/LiveAnnouncements'

export default function AlumniAnnouncementsPage() {
  return <div className="mx-auto max-w-4xl space-y-7 pb-10"><div><h1 className="flex items-center gap-2 text-2xl font-black"><Megaphone className="h-6 w-6 text-primary-purple"/>Department updates</h1><p className="mt-1 text-sm text-text-muted">Live notices for your cohort, including mentorship and alumni opportunities.</p></div><LiveAnnouncements audience="my-batch"/></div>
}
