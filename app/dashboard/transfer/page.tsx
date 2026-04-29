import { Send, Timer, VerifiedIcon } from 'lucide-react'
import React from 'react'
import { BiCheckCircle } from 'react-icons/bi'
import { BsBank } from 'react-icons/bs'
import { MdSend, MdVerified } from 'react-icons/md'
import { TbSend2 } from 'react-icons/tb'

const P2P = () => {
    return (
        <>
            <section className="transfer">


                <form action="">
                    <h3>New Transfer</h3>

                    <div className='item'>
                        <label htmlFor="receiver">Recipient</label>
                        <input type="text" placeholder='Wallet Address' value="" required />
                    </div>
                    <div className='balance'>
                        <label htmlFor="amount">Amount (USDC)</label>
                        <div >
                            <span>Balance:</span>
                            <b>$535,000 USDC</b>
                        </div>
                    </div>
                    <div className='item item2'>

                        <input type="text" name='amount' placeholder='0.00' value="" required />
                        <div>
                            <button>Max</button>
                            <span>USDC</span>
                        </div>
                    </div>

                    <div className="fee">
                        <div className='network'>
                            <span>Network fee</span>
                            <span>0</span>
                        </div>

                        <div>
                            <span>Total to send</span>
                            <span>0</span>
                        </div>

                    </div>
                    <button><MdSend size={16} style={{ marginBottom: "-3px" }} />  Confirm transfer</button>
                </form>
                <div className='txComplete'>
                    <div className='finalized'>
                        <div>
                            <p style={{ color: "green", fontWeight: 600, margin: "10px 0" }}><MdVerified size={18} style={{ marginRight: "10px", marginBottom: "-3px" }} />Transaction finalized</p>
                            <div
                                style={{
                                    display: "flex",
                                    flexDirection: "row",
                                    justifyContent: "space-between",
                                    width: "100%",
                                }}>
                                <span style={{ width: "85%" }}>Your $10,000 has been successfully settled onchain via base.</span>
                                <span style={{ width: "12%" }}><BiCheckCircle size={30} /></span>
                            </div>
                        </div>

                        <div className='view'>
                            <button className='btnn1'>View explorer</button>
                            <button className='btnn2'>Download receipt</button>
                        </div>
                    </div>


                    <div>
                        <div>
                            <span><Timer /></span>
                            <span>Optimal</span>
                        </div>
                        <span>Network speed</span>
                        <h2>0.1s block time</h2>
                    </div>
                    <div>
                        <div>
                            <span><BsBank /></span>
                            <span>Active</span>
                        </div>
                        <span>GAs saved today</span>
                        <h2>$20.3 USD </h2>
                    </div>
                    <div></div>

                </div>
            </section>
            <div>
                <h3>Recent recipients</h3>
            </div>
        </>
    )
}

export default P2P