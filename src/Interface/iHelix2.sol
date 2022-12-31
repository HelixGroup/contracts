//SPDX-License-Identifier: WTFPL.ETH
pragma solidity >0.8.0 <0.9.0;

/**
 * @dev Helix2 Interface
 */
interface iHELIX2 {
    /// @dev : HELIX2 Names external functions
    // write functions

    // view functions
    function isDev() external view returns (address);

    function getRegistrar() external view returns (address[4] memory);

    function getRegistry() external view returns (address[4] memory);

    function getRoothash() external view returns (bytes32[4] memory);

    function getPrices() external view returns (uint256[4] memory);

    function getIllegalBlocks() external view returns (string[4] memory);

    function getSizes() external view returns (uint256[4] memory);

    function getLifespans() external view returns (uint256[4] memory);

    function getContract() external view returns (address);

    // write functions
    function setLives(uint256[4] calldata newLives) external;

    function setLife(uint256 index, uint256 newLife) external;

    function setPrices(uint256[4] calldata newPrices) external;

    function setPrice(uint256 index, uint256 newPrice) external;

    function setRegisteries(address[4] calldata newReg) external;

    function setRegistry(uint256 index, address newReg) external;

    function setRegistrars(uint256[4] calldata newReg) external;

    function setRegistrar(uint256 index, address newReg) external;
}
