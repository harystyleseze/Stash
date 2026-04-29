'use client';
// import { useAppKitAccount } from "@reown/appkit/react"
import { ArrowLeftRightIcon, BoxIcon, Home, HomeIcon, HousePlug, LayoutDashboard, LinkIcon, MenuSquare, PiggyBank, PiggyBankIcon, Settings, Settings2 } from "lucide-react"
import { usePathname } from "next/navigation"
import Link from "next/link"
import { BsBank2 } from "react-icons/bs";
import { TbTransferOut } from "react-icons/tb";
import { MdSend } from "react-icons/md";
export type SidebarProps = {
    dashboardSidebar: boolean
    // onNavigate: (view: string) => void
    // onClick?: () => void          
    style?: React.CSSProperties   // inline styles

}
const Sidebar = () => {
    const pathname = usePathname();


    return (<>

        <aside
            className="nav-sidebar"
        >
            <div className="title" >
                <span><BsBank2 size={22} style={{ marginTop: "6px" }} /></span>
                <h1 >Stash</h1>

            </div>
            <ul>
                <li>
                    <Link
                        href="/dashboard/overview"
                        className={`link ${pathname === '/dashboard/overview' ? 'active' : ''}`}
                    >
                        <div>
                            <span><LayoutDashboard /></span>
                            <span
                            >Overview </span>
                        </div>            </Link>
                </li>
                <li>
                    <Link
                        href="/dashboard/flexible"
                        className={`link ${pathname === '/dashboard/flexible' ? 'active' : ''}`}
                    >
                        <div>
                            <span>< BoxIcon /></span>
                            <span
                            >Flexible </span>
                        </div>            </Link>
                </li>

                <li>
                    <Link
                        href="/dashboard/fixed"
                        className={`link ${pathname === '/dashboard/fixed' ? 'active' : ''}`}
                    >
                        <div>
                            <span><MenuSquare /></span>
                            <span
                            >Fixed</span>
                        </div>            </Link>
                </li>
                <li>
                    <Link
                        href="/dashboard/transfer"
                        className={`link ${pathname === '/dashboard/transfer' ? 'active' : ''}`}
                    >
                        <div>
                            <span><MdSend /></span>
                            <span
                            >P2P Transfer </span>
                        </div>            </Link>
                </li>
                <li>
                    <Link
                        href="/dashboard/settings"
                        className={`link ${pathname === '/settings' ? 'active' : ''}`}
                    >
                        <div>
                            <span><Settings2 /></span>
                            <span
                            >Settings </span>
                        </div>            </Link>
                </li>
            </ul>
        </aside>
    </>)
}

export default Sidebar