import Sidebar from '@/app/ui/sidenav';
import Header from '../ui/header';
import "../ui/styles/dashboard.scss"

export default function Layout({ children }: { children: React.ReactNode }) {
    return (

        <section
            className='dashboard-container'
            style={{ display: "flex", minHeight: "100vh" }}>
            <Sidebar />

            <section
                className='dashboard'
            >
                <Header />
                {children}
            </section>
        </section>
    );
}