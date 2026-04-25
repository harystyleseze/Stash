// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {FlexibleVault} from "../src/FlexibleVault.sol";
import {FixedVault} from "../src/FixedVault.sol";
import {P2PTransfer} from "../src/P2PTransfer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Deploys the three Stash contracts and performs the seed-burn on FlexibleVault.
///         Reads USDC_ADDRESS from env — on a chain without canonical USDC, run
///         DeployMockUSDC.s.sol first and pass the resulting address.
///
/// Requirements:
///   - The broadcasting account must hold at least 1 USDC (1_000_000 base units) for the seed-burn.
///
/// Usage:
///     forge script script/Deploy.s.sol \
///         --rpc-url $LISK_SEPOLIA_RPC_URL \
///         --private-key $PRIVATE_KEY \
///         --broadcast \
///         --verify --verifier blockscout \
///         --verifier-url https://sepolia-blockscout.lisk.com/api
contract Deploy is Script {
    /// @dev 1 USDC (6 decimals).
    uint256 internal constant SEED_AMOUNT = 1e6;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    function run() external returns (FlexibleVault flex, FixedVault fixedV, P2PTransfer p2p) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        require(usdcAddress != address(0), "USDC_ADDRESS must not be zero");

        address deployer = vm.addr(pk);
        IERC20 usdc = IERC20(usdcAddress);

        // Sanity check: deployer holds enough USDC for the seed-burn.
        uint256 deployerBalance = usdc.balanceOf(deployer);
        require(deployerBalance >= SEED_AMOUNT, "Deployer must hold at least 1 USDC for seed-burn");

        vm.startBroadcast(pk);

        // 1. Deploy FlexibleVault.
        flex = new FlexibleVault(usdc, "Stash Flexible USDC", "svfUSDC");

        // 2. Seed-burn: deposit 1 USDC, burn shares to DEAD.
        //    Combined with _decimalsOffset = 6 this ensures the inflation attack is infeasible
        //    even at the first post-deploy interaction.
        usdc.approve(address(flex), SEED_AMOUNT);
        flex.deposit(SEED_AMOUNT, DEAD);

        // 3. Deploy FixedVault.
        fixedV = new FixedVault(usdc);

        // 4. Deploy P2PTransfer.
        p2p = new P2PTransfer(usdc);

        vm.stopBroadcast();

        console.log("============ Stash deployed ============");
        console.log("Chain id:         ", block.chainid);
        console.log("USDC (underlying):", usdcAddress);
        console.log("FlexibleVault:    ", address(flex));
        console.log("FixedVault:       ", address(fixedV));
        console.log("P2PTransfer:      ", address(p2p));
        console.log("Seed burn (USDC): ", SEED_AMOUNT);
        console.log("Seed recipient:   ", DEAD);
        console.log("========================================");
    }
}
