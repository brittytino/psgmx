import LandingNavbar from "@/components/landing/LandingNavbar";
import HeroSection from "@/components/landing/HeroSection";
import FeatureSection from "@/components/landing/FeatureSection";
import AccessSection from "@/components/landing/AccessSection";
import TestimonialSection from "@/components/landing/TestimonialSection";
import LandingFooter from "@/components/landing/LandingFooter";

export const metadata = {
  title: "PSGMX | Placement Operating System",
  description: "Track, prepare, collaborate and succeed—together. Built for PSG Tech MCA.",
};

export default function LandingPage() {
  return (
    <main className="min-h-screen bg-[#FBF6EE] font-sans overflow-x-hidden selection:bg-[#FF6B4A]/20">
      <LandingNavbar />
      <HeroSection />
      <FeatureSection />
      <AccessSection />
      <TestimonialSection />
      <LandingFooter />
    </main>
  );
}
