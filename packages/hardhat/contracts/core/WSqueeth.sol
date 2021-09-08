// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

contract WSqueeth is ERC20, Initializable {
    address public controller;

    constructor() ERC20("Wrapped Squeeth", "WSqueeth") {}

    modifier onlyController() {
        require(msg.sender == controller, "not controller");
        _;
    }

    /**
     * override decimals with 14.
     */
    function decimals() public pure override returns (uint8) {
        return 14;
    }

    function init(address _controller) external initializer {
        controller = _controller;
    }

    function mint(address _account, uint256 _amount) external onlyController {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyController {
        _burn(_account, _amount);
    }
}
