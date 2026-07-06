import type { Metadata } from "next";

import "./globals.css";

import LoadingBar from "@/components/basic/LoadingBar";
import RouteLoadingOverlay from "@/components/basic/RouteLoadingOverlay";
import { Suspense } from "react";
import { UIProvider } from "@/components/providers/ui-provider";
import ImpersonationBanner from "@/components/auth/ImpersonationBanner";


export const metadata: Metadata = {
  metadataBase: new URL("https://psgmx.tech"),
  title: "PSGMX | Department OS",
  description: "The digital soul of the MCA department.",
  icons: {
    icon: "/logo.webp",
  },
  openGraph: {
    title: "PSGMX | Department OS",
    description: "The digital soul of the MCA department.",
    url: "https://psgmx.app",
    siteName: "PSGMX",
    images: [
      {
        url: "/ogimagee.webp",
        width: 1200,
        height: 630,
        alt: "PSGMX Department OS",
      },
    ],
    locale: "en_US",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased bg-page-bg text-text-main font-sans">
        <ImpersonationBanner />
        <UIProvider>
          <Suspense fallback={null}>
            <LoadingBar />
            <RouteLoadingOverlay />
          </Suspense>
          {children}
        </UIProvider>
      </body>
    </html>
  );
}
