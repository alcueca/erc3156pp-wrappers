// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { FlashBorrower } from "./FlashBorrower.sol";
import { IERC20, AaveWrapper } from "../src/aave/AaveWrapper.sol";
import { IPoolAddressesProvider } from "../src/aave/interfaces/IPoolAddressesProvider.sol";

import { BaseWrapper } from "src/BaseWrapper.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract AaveWrapperTest is PRBTest, StdCheats {
    AaveWrapper internal wrapper;
    FlashBorrower internal borrower;
    IERC20 internal dai;
    IPoolAddressesProvider internal provider;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Revert if there is no API key.
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            revert("API_KEY_ALCHEMY variable missing");
        }

        vm.createSelectFork({ urlOrAlias: "arbitrum_one", blockNumber: 98_674_994 });
        provider = IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);
        dai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);

        wrapper = new AaveWrapper(provider);
        borrower = new FlashBorrower(wrapper);
        deal(address(dai), address(this), 1e18); // For fees
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_flashFee() external {
        console2.log("test_flashFee");
        assertEq(wrapper.flashFee(dai, 1e18), 5e14, "Fee not right");
        assertEq(wrapper.flashFee(dai, type(uint256).max), type(uint256).max, "Fee not max");
    }

    function test_flashLoan() external {
        console2.log("test_flashLoan");
        uint256 loan = 1e18;
        uint256 fee = wrapper.flashFee(dai, loan);
        dai.transfer(address(borrower), fee);
        bytes memory result = borrower.flashBorrow(dai, loan);

        // Test the return values
        (bytes32 callbackReturn) = abi.decode(result, (bytes32));
        assertEq(uint256(callbackReturn), uint256(borrower.ERC3156PP_CALLBACK_SUCCESS()), "Callback failed");

        // Test the borrower state
        assertEq(borrower.flashInitiator(), address(borrower));
        assertEq(address(borrower.flashAsset()), address(dai));
        assertEq(borrower.flashAmount(), loan);
        assertEq(borrower.flashBalance(), loan + fee); // The amount we transferred to pay for fees, plus the amount we
            // borrowed
        assertEq(borrower.flashFee(), fee);
    }

    function test_executeOperation_permissions() public {
        vm.expectRevert("AaveFlashLoanProvider: not pool");
        wrapper.executeOperation({ asset: address(dai), amount: 1e18, fee: 0, initiator: address(wrapper), params: "" });

        vm.prank(provider.getPool());
        vm.expectRevert("AaveFlashLoanProvider: not initiator");
        wrapper.executeOperation({ asset: address(dai), amount: 1e18, fee: 0, initiator: address(0x666), params: "" });
    }

    function test_setExpectedGas() external {
        console2.log("test_setExpectedGas");

        uint256 loan = 1e18;
        uint256 fee = wrapper.flashFee(dai, loan);
        dai.transfer(address(wrapper), fee);

        uint256 expectedGas = wrapper.setExpectedGas(dai);

        console2.log(expectedGas, "expectedGas");
        assertGt(expectedGas, 0, "Expected gas not set");
        assertEq(expectedGas, wrapper.expectedGas(), "Return value doesn't match");
    }
}
