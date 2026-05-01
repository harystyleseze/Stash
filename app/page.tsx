import Image from "next/image";
import Link from "next/link";
import { ArrowRight, ShieldCheck, TrendingUp, Wallet } from "lucide-react";
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

export default function Home() {
    return (
        <main className={styles.landingPage}>
            <section className={styles.heroSection}>
                <div className={styles.heroInner}>
                    <header className={styles.navbar}>
                        <Link href="/" className={styles.brand}>
                            <span className={styles.brandMark}>S</span>
                            <span>stash</span>
                        </Link>

                        <div className={styles.navActions}>
                            <Link href="/dashboard/overview" className={styles.navLink}>
                                Dashboard
                            </Link>
                            <Link href="/dashboard/flexible" className={styles.navButton}>
                                Start saving
                            </Link>
                        </div>
                    </header>

                    <div className={styles.heroShell}>
                        <div className={styles.heroBackdrop} aria-hidden="true" />

                        <div className={styles.heroCopy}>
                            {/* <span className={styles.eyebrow}>Stablecoin neobank</span> */}
                            <h1>Digital dollar banking that feels calm, clear, and beautifully simple.</h1>
                            <p>
                                Stash brings spending, transfers, and savings into one thoughtful workspace
                                for people who want stablecoin money management to feel less technical and
                                more natural.
                            </p>

                            <div className={styles.heroActions}>
                                <Link href="/dashboard/overview" className={styles.primaryButton}>
                                    Open dashboard
                                    <ArrowRight size={18} />
                                </Link>
                                <Link href="/dashboard/flexible" className={styles.secondaryButton}>
                                    Explore savings
                                </Link>
                            </div>
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
    );
}
