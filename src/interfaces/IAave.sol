// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPOOL {
    function supply (
        address asset,
        uint amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function getUserAccountData(address user) external view returns (
        uint totalCollateralBase,
        uint totalDebtBase, 
        uint availableBorrowBase,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor);

    function borrow(
        address asset,
        uint amount,
        uint interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint amount,
        uint rateMode,
        address onBehalfOf
    ) external;

    function withdraw(
        address asset,
        uint amount,
        address to
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}
