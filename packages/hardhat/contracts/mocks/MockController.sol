// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import {IShortPowerPerp} from "../interfaces/IShortPowerPerp.sol";
import {IWPowerPerp} from "../interfaces/IWPowerPerp.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {VaultLib} from "../libs/VaultLib.sol";

contract MockController {
    using SafeMath for uint256;
    using VaultLib for VaultLib.Vault;
    using Address for address payable;

    uint256 internal constant secInDay = 86400;

    uint256 public normalizationFactor;

    /// @dev The token ID vault data
    mapping(uint256 => VaultLib.Vault) public vaults;

    IWPowerPerp public wPowerPerp;
    IShortPowerPerp public shortPowerPerp;

    function init(address _shortPowerPerp, address _wPowerPerp) public {
        require(_shortPowerPerp != address(0), "Invalid shortPowerPerp address");
        require(_wPowerPerp != address(0), "Invalid wPowerPerp address");

        shortPowerPerp = IShortPowerPerp(_shortPowerPerp);
        wPowerPerp = IWPowerPerp(_wPowerPerp);

        normalizationFactor = 1e18;
    }

    function mintWPowerPerpAmount(
        uint256 _vaultId,
        uint128 _mintAmount,
        uint256 /*_nftTokenId*/
    ) external payable returns (uint256, uint256) {
        uint256 wSqueethMinted;

        if (_vaultId == 0) _vaultId = _openVault(msg.sender);
        if (msg.value > 0) _addEthCollateral(_vaultId, msg.value);
        if (_mintAmount > 0) {
            wSqueethMinted = _addShort(msg.sender, _vaultId, _mintAmount);
        }

        return (_vaultId, wSqueethMinted);
    }

    function burnWPowerPerpAmount(
        uint256 _vaultId,
        uint256 _amount,
        uint256 _withdrawAmount
    ) external {
        if (_amount > 0) _removeShort(msg.sender, _vaultId, _amount);
        if (_withdrawAmount > 0) _withdrawCollateral(msg.sender, _vaultId, _withdrawAmount);
        if (_withdrawAmount > 0) payable(msg.sender).sendValue(_withdrawAmount);
    }

    function _openVault(address _recipient) internal returns (uint256) {
        uint256 vaultId = shortPowerPerp.mintNFT(_recipient);
        vaults[vaultId] = VaultLib.Vault({
            NftCollateralId: 0,
            collateralAmount: 0,
            shortAmount: 0,
            operator: address(0)
        });

        return vaultId;
    }

    function _addEthCollateral(uint256 _vaultId, uint256 _amount) internal {
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        cachedVault.addEthCollateral(uint128(_amount));
        vaults[_vaultId] = cachedVault;
    }

    function _withdrawCollateral(
        address _account,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        cachedVault.removeEthCollateral(_amount);
        vaults[_vaultId] = cachedVault;
    }

    function _addShort(
        address _account,
        uint256 _vaultId,
        uint256 _squeethAmount
    ) internal returns (uint256 amountToMint) {
        require(_canModifyVault(_vaultId, _account), "not allowed");

        amountToMint = _squeethAmount.mul(1e18).div(normalizationFactor);

        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        cachedVault.addShort(amountToMint);
        vaults[_vaultId] = cachedVault;

        wPowerPerp.mint(_account, amountToMint);
    }

    function _removeShort(
        address _account,
        uint256 _vaultId,
        uint256 _amount
    ) internal {
        VaultLib.Vault memory cachedVault = vaults[_vaultId];
        cachedVault.removeShort(_amount);
        vaults[_vaultId] = cachedVault;

        wPowerPerp.burn(_account, _amount);
    }

    function _canModifyVault(uint256 _vaultId, address _account) internal view returns (bool) {
        return shortPowerPerp.ownerOf(_vaultId) == _account || vaults[_vaultId].operator == _account;
    }
}
