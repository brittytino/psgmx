import { Resend } from 'resend';

const RESEND_API_KEY = process.env.RESEND_API_KEY || '';
export const resend = new Resend(RESEND_API_KEY);

export const PRIMARY_FROM = 'PSGMX <notifications@psgmx.tech>';
export const FALLBACK_FROM = 'PSGMX <onboarding@resend.dev>';

/**
 * Sends a clean, premium 6-digit OTP verification email
 */
export async function sendOtpEmail(toEmail: string, otpCode: string): Promise<{ success: boolean; data?: any; error?: any }> {
  const subject = `${otpCode} is your PSGMX login code`;

  const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>${otpCode} — PSGMX Verification</title>
  <!--[if mso]>
  <style type="text/css">
    body, table, td { font-family: Arial, Helvetica, sans-serif !important; }
  </style>
  <![endif]-->
</head>
<body style="margin: 0; padding: 0; background-color: #F8F9FA; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; color: #1F2937;">
  <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F8F9FA; padding: 40px 16px;">
    <tr>
      <td align="center">
        <!-- Main Card -->
        <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 480px; background-color: #FFFFFF; border-radius: 16px; border: 1px solid #E5E7EB; box-shadow: 0 4px 20px rgba(0, 0, 0, 0.05); overflow: hidden;">
          
          <!-- Header Bar -->
          <tr>
            <td style="padding: 36px 36px 20px 36px;">
              <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>
                    <div style="display: inline-block; font-size: 20px; font-weight: 800; letter-spacing: -0.02em; color: #111827;">
                      PSG<span style="color: #FF5A1F;">MX</span>
                    </div>
                  </td>
                  <td align="right">
                    <span style="font-size: 11px; font-weight: 600; color: #6B7280; text-transform: uppercase; letter-spacing: 0.08em; background-color: #F3F4F6; padding: 4px 10px; border-radius: 20px;">
                      MCA Portal
                    </span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding: 0 36px;">
              <div style="height: 1px; background-color: #F3F4F6; width: 100%;"></div>
            </td>
          </tr>

          <!-- Content Body -->
          <tr>
            <td style="padding: 32px 36px 28px 36px;">
              <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 700; color: #111827; letter-spacing: -0.02em;">
                Verification Code
              </h1>
              <p style="margin: 0 0 28px 0; font-size: 14px; line-height: 1.5; color: #4B5563;">
                Enter this 6-digit code on the sign-in screen to access your account:
              </p>

              <!-- OTP Code Display -->
              <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F9FAFB; border: 1px solid #E5E7EB; border-radius: 12px; margin-bottom: 24px;">
                <tr>
                  <td align="center" style="padding: 24px 16px;">
                    <div style="font-family: 'SF Mono', SFMono-Regular, Consolas, Menlo, monospace; font-size: 36px; font-weight: 700; letter-spacing: 0.28em; color: #111827; padding-left: 0.28em;">
                      ${otpCode}
                    </div>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 24px 0; font-size: 13px; color: #6B7280; text-align: center;">
                ⏱️ This single-use code is valid for <strong>10 minutes</strong>.
              </p>

              <div style="background-color: #FEF3C7; border-left: 3px solid #F59E0B; padding: 12px 14px; border-radius: 0 8px 8px 0;">
                <p style="margin: 0; font-size: 12px; line-height: 1.4; color: #92400E;">
                  <strong>Security Reminder:</strong> Never share this code with anyone. PSG Tech administrators will never ask for your verification code.
                </p>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #F9FAFB; border-top: 1px solid #E5E7EB; padding: 24px 36px; text-align: center;">
              <p style="margin: 0 0 6px 0; font-size: 12px; font-weight: 600; color: #4B5563;">
                PSG College of Technology · Department of Computer Applications
              </p>
              <p style="margin: 0; font-size: 11px; line-height: 1.4; color: #9CA3AF;">
                If you didn&apos;t request this code, you can safely disregard this email.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;

  return sendEmailWithFallback(toEmail, subject, htmlContent);
}

/**
 * Sends a clean Welcome email to newly rostered students
 */
export async function sendWelcomeEmail(toEmail: string, studentName: string, regNo: string): Promise<{ success: boolean; data?: any; error?: any }> {
  const subject = `Welcome to PSGMX (${regNo})`;

  const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to PSGMX</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F8F9FA; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1F2937;">
  <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #F8F9FA; padding: 40px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 500px; background-color: #FFFFFF; border-radius: 16px; border: 1px solid #E5E7EB; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.05);">
          <tr>
            <td style="padding: 32px 32px 16px 32px;">
              <div style="font-size: 22px; font-weight: 800; color: #111827;">PSG<span style="color: #FF5A1F;">MX</span></div>
            </td>
          </tr>
          <tr>
            <td style="padding: 16px 32px 32px 32px; line-height: 1.6; font-size: 14px; color: #4B5563;">
              <h2 style="margin: 0 0 12px 0; font-size: 20px; font-weight: 700; color: #111827;">Welcome, ${studentName}</h2>
              <p style="margin: 0 0 16px 0;">You have been enrolled into the PSGMX Placement Readiness Companion for batch <strong>${regNo}</strong>.</p>
              <div style="margin: 24px 0;">
                <a href="https://psgmx.tech/login" style="display: inline-block; background-color: #FF5A1F; color: #FFFFFF; text-decoration: none; padding: 12px 24px; border-radius: 10px; font-weight: 600; font-size: 14px;">Sign In to Your Workspace</a>
              </div>
              <p style="margin: 0; font-size: 12px; color: #9CA3AF;">Use your registered email (${toEmail}) on the login page to receive your secure 6-digit OTP.</p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #F9FAFB; border-top: 1px solid #E5E7EB; padding: 20px 32px; text-align: center; font-size: 11px; color: #9CA3AF;">
              PSG College of Technology · MCA Department
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;

  return sendEmailWithFallback(toEmail, subject, htmlContent);
}

/**
 * Fast sender using verified domain notifications@psgmx.tech
 */
async function sendEmailWithFallback(toEmail: string, subject: string, htmlContent: string) {
  try {
    const result = await resend.emails.send({
      from: PRIMARY_FROM,
      to: toEmail,
      subject,
      html: htmlContent,
    });

    if (result.error) {
      console.warn('[Resend] Primary domain send warning, attempting fallback:', result.error);
      const fallbackResult = await resend.emails.send({
        from: FALLBACK_FROM,
        to: toEmail,
        subject,
        html: htmlContent,
      });

      if (fallbackResult.error) {
        return { success: false, error: fallbackResult.error };
      }
      return { success: true, data: fallbackResult.data };
    }

    return { success: true, data: result.data };
  } catch (err: any) {
    console.error('[Resend] Send exception:', err);
    try {
      const fallbackResult = await resend.emails.send({
        from: FALLBACK_FROM,
        to: toEmail,
        subject,
        html: htmlContent,
      });
      return { success: !fallbackResult.error, data: fallbackResult.data, error: fallbackResult.error };
    } catch (fallbackErr: any) {
      return { success: false, error: fallbackErr };
    }
  }
}
