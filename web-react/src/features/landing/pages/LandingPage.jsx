import LandingNavbar from '../components/LandingNavbar'
import HeroSection from '../components/HeroSection'
import StatsBar from '../components/StatsBar'
import DriverStepsSection from '../components/DriverStepsSection'
import StationOwnerSection from '../components/StationOwnerSection'
import AiFeaturesSection from '../components/AiFeaturesSection'
import TestimonialsSection from '../components/TestimonialsSection'
import CtaBanner from '../components/CtaBanner'
import LandingFooter from '../components/LandingFooter'

/**
 * Public marketing landing page — the app entry point at "/".
 * All CTAs route to /login, which then forwards to the role dashboard.
 */
export default function LandingPage() {
  return (
    <div className="min-h-screen bg-surface font-sans text-on-surface antialiased">
      <LandingNavbar />
      <main className="w-full pt-16">
        <HeroSection />
        <StatsBar />
        <DriverStepsSection />
        <StationOwnerSection />
        <AiFeaturesSection />
        <TestimonialsSection />
        <CtaBanner />
        <LandingFooter />
      </main>
    </div>
  )
}
