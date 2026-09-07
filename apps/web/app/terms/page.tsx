import type { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Terms of Service | PSGMX',
  description: 'Terms for using the PSGMX preparation companion at PSG Tech MCA.',
}

export default function TermsOfServicePage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-[#221F1A]">
      <Link href="/" className="text-sm font-bold text-[#FF6B4A]">← Back to PSGMX</Link>
      <h1 className="mt-6 text-3xl font-black">Terms of Service</h1>
      <p className="mt-2 text-sm text-[#9E9A92]">Last updated: {new Date().toISOString().slice(0, 10)}</p>

      <div className="mt-8 space-y-8 text-[15px] leading-7 text-[#4A463E]">
        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Who this is for</h2>
          <p className="mt-2">PSGMX is available only to current students, faculty and verified alumni of the MCA programme at PSG College of Technology. Access is granted through your institutional or verified personal email — there is no public sign-up.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Not an official placement system</h2>
          <p className="mt-2">PSGMX is a preparation companion. It does not schedule placement drives, issue hall tickets, or announce offers. NEO PAT remains the official system of record for all placement drives, eligibility, applications and shortlists.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Your responsibilities</h2>
          <ul className="mt-2 list-disc space-y-1.5 pl-5">
            <li>Keep your account credentials (OTP access to your email) private — do not share access with anyone else.</li>
            <li>Submit your own work in CodeBox, assessments and knowledge-brain contributions.</li>
            <li>Do not post confidential interview questions, private interviewer details, or unverified claims about active official drives in the Interview Pattern Library or Knowledge Brain.</li>
            <li>Placement representatives and faculty must use administrative access only for legitimate programme operation.</li>
          </ul>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Content moderation</h2>
          <p className="mt-2">Knowledge Brain articles and Interview Pattern Library submissions are reviewed by faculty before becoming visible to others. PSGMX may remove content that is inaccurate, violates confidentiality, or misrepresents official placement information.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">AI features</h2>
          <p className="mt-2">AI Senior, AI Mentor, and CodeBox's AI evaluation use third-party language models to generate guidance and feedback. Responses are grounded in approved Knowledge Brain content where possible but may still be incomplete or imperfect — always verify official placement details through NEO PAT, not through AI features.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Availability</h2>
          <p className="mt-2">PSGMX runs on free-tier infrastructure (Vercel, Supabase, and free AI model tiers). It is provided as-is, without uptime guarantees, as an internal departmental tool.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Contact</h2>
          <p className="mt-2">Questions about these terms can be raised at <Link href="https://github.com/brittytino/psgmx/issues" target="_blank" className="font-bold text-[#FF6B4A] underline">github.com/brittytino/psgmx/issues</Link>.</p>
        </section>
      </div>
    </div>
  )
}
