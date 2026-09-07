import type { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Privacy Policy | PSGMX',
  description: 'How PSGMX handles data for PSG Tech MCA students, faculty and alumni.',
}

export default function PrivacyPolicyPage() {
  return (
    <div className="mx-auto max-w-3xl px-6 py-16 text-[#221F1A]">
      <Link href="/" className="text-sm font-bold text-[#FF6B4A]">← Back to PSGMX</Link>
      <h1 className="mt-6 text-3xl font-black">Privacy Policy</h1>
      <p className="mt-2 text-sm text-[#9E9A92]">Last updated: {new Date().toISOString().slice(0, 10)}</p>

      <div className="mt-8 space-y-8 text-[15px] leading-7 text-[#4A463E]">
        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">What PSGMX is</h2>
          <p className="mt-2">PSGMX is an internal preparation and placement-readiness companion built for MCA students, faculty and alumni at PSG College of Technology. It is not a commercial product, does not run advertising, and does not sell data to any third party.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">What we collect</h2>
          <ul className="mt-2 list-disc space-y-1.5 pl-5">
            <li>Identity and academic details you or your institution provide: name, register number, batch, department email, and role (student, faculty, HOD, placement representative, alumni).</li>
            <li>Preparation activity you generate while using the platform: CodeBox submissions, assessment attempts, readiness evidence, FYP records, knowledge-brain contributions, and communication-practice recordings.</li>
            <li>Basic technical data needed to keep you signed in (session cookies) and to prevent abuse (rate limiting, audit logs of sensitive actions).</li>
          </ul>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">How sign-in works</h2>
          <p className="mt-2">PSGMX uses one-time-password (OTP) email verification instead of stored passwords. OTPs are delivered via Resend and expire shortly after they are issued.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Third-party processors</h2>
          <p className="mt-2">Data is processed using the following services, each under its own privacy terms:</p>
          <ul className="mt-2 list-disc space-y-1.5 pl-5">
            <li><strong>Supabase</strong> — database, authentication and file storage.</li>
            <li><strong>Resend</strong> — transactional email delivery (OTPs, notifications).</li>
            <li><strong>Google Gemini / OpenRouter</strong> — AI features such as AI Senior, AI Mentor, and CodeBox evaluation. Code and questions you submit to these features are sent to the selected model provider for that request only.</li>
            <li><strong>Piston (emkc.org)</strong> — sandboxed execution of code you submit in CodeBox.</li>
            <li><strong>Vercel</strong> — application hosting.</li>
          </ul>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Who can see your data</h2>
          <p className="mt-2">Access is restricted by role: students see their own preparation data; placement representatives and faculty can see batch-scoped data required for mentoring and administration; HODs have department-wide governance access. Alumni contributions marked anonymous still record an internal author reference for moderation, but the author's name is withheld from other readers where the feature supports it.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Data retention</h2>
          <p className="mt-2">Preparation history is preserved as a permanent academic and alumni record — this is a core part of what PSGMX is for. You can request correction or removal of specific personal data by contacting us (see below); some records may be retained where required for academic integrity or institutional record-keeping.</p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-[#221F1A]">Contact</h2>
          <p className="mt-2">For any privacy question or data request, open an issue at <Link href="https://github.com/brittytino/psgmx/issues" target="_blank" className="font-bold text-[#FF6B4A] underline">github.com/brittytino/psgmx/issues</Link>.</p>
        </section>
      </div>
    </div>
  )
}
