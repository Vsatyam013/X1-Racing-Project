//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


/**
 * @title DecentralizedStableCoin
 * @author Satyam Verma
 * Minting: Alogithmic
 */ 

contract x1Coin is ERC20Burnable, Ownable {
    error x1Coin__MustBeMoreThanZero();
    error x1Coin__BurnAmountExceedsBalance();
    error x1Coin__NotZeroAddress();

    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens

    constructor() ERC20("x1Coin","x1Racing") {
        // Mint 1 billion tokens to the contract deployer
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if(_amount <= 0){
            revert x1Coin__MustBeMoreThanZero();
        }
        if(balance < _amount) {
            revert x1Coin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if(_to==address(0)) {
            revert x1Coin__NotZeroAddress();
        }
        if(_amount <= 0) {
            revert x1Coin__MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }

}
