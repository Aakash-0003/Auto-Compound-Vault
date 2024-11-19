// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPlugIn {
    function balanceOf(address account) external view returns (uint256);
    function depositFor(address account, uint256 amount) external;
    function withdrawTo(address account, uint256 amount) external;
}
