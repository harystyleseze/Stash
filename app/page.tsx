// import Image from "next/image";

import Link from "next/link";

export default function Home() {
    return (
        <main
            style={{ alignContent: "center" }}
        >
            <Link
                href="/dashboard/overview"
            >

                Go to dashboard
            </Link>

        </main>
    );
}
