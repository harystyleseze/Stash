import Image from "next/image";
import { ShieldCheck, TrendingUp, Wallet } from "lucide-react";
import LandingTestimonials from "./ui/landing-testimonials";
import LandingHeader from "./ui/landing-header";
import LandingFooter from "./ui/landing-footer";
import { LandingHeroCta } from "@/components/shared/landing-hero-cta";
import { AutoRedirectOnConnect } from "@/components/shared/auto-redirect-on-connect";
import styles from "./page.module.css";

const features = [
    {
        title: "Spend-ready balances",
        description:
            "See what is available now, what is earning, and what needs to move next without hunting across screens.",
        accent: "Daily clarity",
        icon: Wallet,
    },
    {
        title: "Yield without friction",
        description:
            "Put idle funds into flexible savings and keep the experience lightweight enough for everyday use.",
        accent: "Passive growth",
        icon: TrendingUp,
    },
    {
        title: "Calm operational control",
        description:
            "Move stablecoins confidently with a simpler flow, cleaner numbers, and less noise around each action.",
        accent: "Confident movement",
        icon: ShieldCheck,
    },
];

const testimonials = [
    {
        quote:
            "Stash is the first stablecoin app I have used that feels calm enough for daily money movement. I do not need to think twice before opening it.",
        name: "Amara Yusuf",
        role: "Operations lead",
        stat: "Treasury transfers every week",
        image: "/happy customer.jpg",
    },
    {
        quote:
            "The savings flow feels simple, not intimidating. I can see what is available, what is earning, and move between both without the usual confusion.",
        name: "Daniel Cole",
        role: "Founder",
        stat: "Uses flexible vaults daily",
        image: "/customer.jpg",
    },
    {
        quote:
            "What kept me around was the clarity. It feels more like a polished neobank than a crypto dashboard stitched together from too many ideas.",
        name: "Teni Adebayo",
        role: "Finance manager",
        stat: "Runs team payouts in USDC",
        image: "/happy customer.jpg",
    },
];

export default function Home() {
    return (
        <>
            <AutoRedirectOnConnect to="/dashboard/overview" />
            <main className={styles.landingPage}>
                <section className={styles.heroSection}>
                    <div className={styles.heroInner}>
                        <LandingHeader />

                        <div className={styles.heroShell}>
                            <div className={styles.heroBackdrop} aria-hidden="true" />

                            <div className={styles.heroCopy}>
                                <h1>Digital dollar banking that feels calm, clear, and beautifully simple.</h1>
                                <p>
                                    Stash brings spending, transfers, and savings into one thoughtful workspace
                                    for people who want stablecoin money management to feel less technical and
                                    more natural.
                                </p>

                                <LandingHeroCta />
                            </div>

                            <div className={styles.heroVisual}>
                                <div className={styles.heroPhotoCard}>
                                    <Image
                                        src="/happy customer.jpg"
                                        alt="Happy customer using Stash"
                                        width={920}
                                        height={1080}
                                        className={styles.heroImage}
                                        priority
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                <LandingTestimonials items={testimonials} />

                <section className={styles.featureSection}>
                    <div className={styles.sectionHeading}>
                        <span className={styles.sectionEyebrow}>Core value</span>
                        <h2>Useful features, presented with a little more taste.</h2>
                    </div>

                    <div className={styles.featureGrid}>
                        {features.map(({ title, description, accent, icon: Icon }) => (
                            <article key={title} className={styles.featureCard}>
                                <span className={styles.featureAccent}>{accent}</span>
                                <span className={styles.featureIcon}>
                                    <Icon size={20} />
                                </span>
                                <h3>{title}</h3>
                                <p>{description}</p>
                            </article>
                        ))}
                    </div>
                </section>
            </main>
            <LandingFooter />
        </>
    );
}
